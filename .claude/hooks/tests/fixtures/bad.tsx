export function Card({ data }: { data: unknown }) {
  const user = data as { name: string }; // expect: TS-AS
  const ref = useRef<HTMLDivElement>(null);
  const width = ref.current!.offsetWidth; // expect: TS-NONNULL
  const items: any = []; // expect: TS-ANY
  return <div ref={ref}>{user.name}{width}{items}</div>;
}
