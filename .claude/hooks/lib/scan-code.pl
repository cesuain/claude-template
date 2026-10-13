#!/usr/bin/env perl
# Mechanical rule scanner used by check-code.sh. Usage: scan-code.pl <file>
# Prints "<file>:<line> [RULE] message" per finding. Comments, strings, regex literals and JSX text are blanked first.
use strict; use warnings;
my $path = $ARGV[0];
open(my $fh, '<', $path) or exit 0; local $/; my $src = <$fh>; close $fh;
my $is_tsx = $path =~ /\.(tsx|jsx)$/;
my $is_ts_plain = $path =~ /\.(ts|mts|cts)$/;
my @raw = split /\n/, $src, -1;
my @out;
sub flag { my ($ln, $rule, $msg) = @_; my $s = $raw[$ln-1] // ''; $s =~ s/^\s+//; $s = substr($s,0,120);
  push @out, "$path:$ln [$rule] $msg\n    > $s"; }

# --- ts-ignore family (in comments, so check raw) ---
for my $i (0..$#raw) { flag($i+1,'TS-IGNORE','suppression comment; fix the type instead') if $raw[$i] =~ /\@ts-(ignore|nocheck|expect-error)\b/; }

# --- blank comments, string/template/regex literal contents (keep length + newlines) ---
my @c = split //, $src; my $n = @c; my $i = 0; my @tpl; my $prev = '';
my $blank = sub { $c[$_[0]] = ' ' unless $c[$_[0]] eq "\n"; };
# scan template literal text from $i until closing ` or ${ (pushes a brace counter)
my $tpl_scan = sub {
  while ($i < $n && $c[$i] ne '`') {
    if ($c[$i] eq '\\') { $blank->($i++); $blank->($i++) if $i<$n; next; }
    if ($c[$i] eq '$' && $i+1<$n && $c[$i+1] eq '{') { $i += 2; push @tpl, 0; return; }
    $blank->($i++);
  }
  if ($i < $n) { $i++; $prev = '`'; }
};
while ($i < $n) {
  my $ch = $c[$i]; my $nx = $i+1 < $n ? $c[$i+1] : '';
  if (@tpl && $ch eq '}' && $tpl[-1] == 0) { pop @tpl; $i++; $tpl_scan->(); next; }
  if (@tpl) { $tpl[-1]++ if $ch eq '{'; $tpl[-1]-- if $ch eq '}'; }
  if ($ch eq '/' && $nx eq '/') { while ($i < $n && $c[$i] ne "\n") { $blank->($i++) } next; }
  if ($ch eq '/' && $nx eq '*') { while ($i < $n && !($c[$i] eq '*' && $i+1<$n && $c[$i+1] eq '/')) { $blank->($i++) } $blank->($i++) if $i<$n; $blank->($i++) if $i<$n; next; }
  if ($ch eq "'" || $ch eq '"') { my $q = $ch; $i++;
    while ($i < $n && $c[$i] ne $q && $c[$i] ne "\n") { if ($c[$i] eq '\\') { $blank->($i++); } $blank->($i++) if $i<$n; }
    $i++; $prev = $q; next; }
  if ($ch eq '/' && $prev =~ /^[(,=:\[!&|?{};+\-*%<>~^]?$/ ) { # regex literal
    my $j = $i+1; my $cls = 0; my $ok = 0;
    while ($j < $n && $c[$j] ne "\n") { if ($c[$j] eq '\\') { $j += 2; next } $cls = 1 if $c[$j] eq '['; $cls = 0 if $c[$j] eq ']';
      if ($c[$j] eq '/' && !$cls) { $ok = 1; last } $j++; }
    if ($ok) { $blank->($_) for ($i+1 .. $j-1); $i = $j+1; $prev = '/'; next; }
  }
  if ($ch eq '`') { $i++; $tpl_scan->(); next; }
  $prev = $ch unless $ch =~ /\s/;
  $i++;
}
my $code = join '', @c;
my @lines = split /\n/, $code, -1;

# --- JSX text: blank prose between tags / prose-only lines (tsx/jsx) ---
if ($is_tsx) {
  for (@lines) {
    s/(?<=>)([^<>{}()=;]*)(?=<|$)/' ' x length($1)/ge if /<\/?[A-Za-z]/;
    if (/^\s*[A-Za-z][^;={}()<>\[\]:]*$/ && !/^\s*(return|const|let|var|await|yield|throw|export|import|type|interface|if|else|case|default|function|async)\b/) { $_ = ' ' x length($_); }
  }
}

# --- line rules ---
my $in_import = 0;
for my $k (0..$#lines) {
  my $l = $lines[$k]; my $ln = $k+1;
  my $is_mod = $l =~ /^\s*(?:import\b(?!\s*\()|export\s+(?:type\s+)?[{*])/;  # import lines, export { } / export * re-exports
  if ($is_mod && $l =~ /\{/ && $l !~ /\}/) { $in_import = 1; next; }
  if ($in_import) { $in_import = 0 if $l =~ /\}/; next; }
  unless ($is_mod) {
    flag($ln,'TS-AS','type assertion; narrow with a type guard or validate with Zod (as const / satisfies are fine)')
      if $l =~ /(?<=[\w)\]}'"`>])\s+as\s+(?!const\b)(?=[A-Za-z_{\[(<])/;
  }
  if ($is_ts_plain && $l =~ /(?:[=(,:?]|\breturn)\s*<\s*(?:[A-Z]\w*|string|number|boolean|unknown|any)(?:\[\])?\s*>\s*([\w(\[{'"`].*)$/) {
    my $rest = $1;
    flag($ln,'TS-ANGLE','angle-bracket type assertion; narrow or validate instead') unless $rest =~ /^\([^)]*\)\s*(?::[^=]*)?=>/;
  }
  flag($ln,'TS-NONNULL','non-null assertion; handle the undefined/null case explicitly')
    if $l =~ /(?<=[\w)\]])!(?!=)(?=\s*[.\[(),;:]|\s*$)/;
  flag($ln,'TS-ANY','explicit any; use unknown + narrowing, a Zod schema, or a derived type')
    if $l =~ /(?:[:<,|&]|\bas|\btype\s+\w+\s*=)\s*any\b(?![\w\$(])/ || $l =~ /(?<![\w.\$])any\s*\[\]/;
  if ($l =~ /JSON\.parse\s*\(/) {
    my $win = join "\n", grep { defined } @lines[$k .. ($k+2 > $#lines ? $#lines : $k+2)];
    (my $w2 = $win) =~ s/JSON\.parse//g;
    flag($ln,'JSON-NO-ZOD','JSON.parse result must be validated with a Zod schema (.parse/.safeParse) or use parseJson(schema, text)')
      unless $w2 =~ /\.(?:safeParse|parse|parseAsync|safeParseAsync)\s*\(/;
  }
}

# --- silent catch (block-aware on blanked code) ---
my $logs = qr/\b(?:reportError|reportSchemaViolation|captureException|Sentry\.capture\w+|logger\.(?:error|warn|fatal)|log\.(?:error|warn)|console\.(?:error|warn)|throw\b|next\s*\(\s*\w+|reject\s*\()/;
sub line_of { my $off = shift; return 1 + (() = substr($code, 0, $off) =~ /\n/g); }
sub match_close { my ($pos, $open, $close) = @_; my $d = 0;
  for (my $j = $pos; $j < length $code; $j++) { my $ch = substr($code,$j,1); $d++ if $ch eq $open; if ($ch eq $close) { $d--; return $j if $d == 0; } } return -1; }
while ($code =~ /\bcatch\s*(?:\([^)]*\))?\s*\{/g) {
  my $at = $-[0]; my $start = $+[0]-1; my $end = match_close($start,'{','}'); next if $end < 0;
  my $body = substr($code, $start+1, $end-$start-1);
  if ($body !~ /\S/) { flag(line_of($at),'SILENT-CATCH','empty catch block; log with reportError(err, {...}) or rethrow'); }
  elsif ($body !~ $logs) { flag(line_of($at),'SILENT-CATCH','catch without logging or rethrow; call reportError(err, {...})'); }
}
while ($code =~ /\.catch\s*\(/g) {
  my $at = $-[0]; my $start = $+[0]-1; my $end = match_close($start,'(',')'); next if $end < 0;
  my $args = substr($code, $start+1, $end-$start-1);
  flag(line_of($at),'SILENT-CATCH','.catch handler swallows the error; call reportError or rethrow') unless $args =~ $logs;
}
print join("\n", @out), "\n" if @out;
