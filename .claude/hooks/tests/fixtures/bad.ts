import { z } from 'zod';

const User = z.object({ id: z.string() });

export function a(input: unknown) {
  const u = input as { id: string }; // expect: TS-AS
  const v = input as unknown as number; // expect: TS-AS
  const w = (input) as User; // expect: TS-AS
  const x = <User>input; // expect: TS-ANGLE
  return [u, v, w, x];
}

export function b(map: Map<string, string>) {
  const val = map.get('k')!; // expect: TS-NONNULL
  const len = map.get('k')!.length; // expect: TS-NONNULL
  return [val, len];
}

class Svc {
  client!: string; // expect: TS-NONNULL
}

export function c(data: any) { // expect: TS-ANY
  const list: any[] = []; // expect: TS-ANY
  const rec: Record<string, any> = {}; // expect: TS-ANY
  type Loose = any; // expect: TS-ANY
  return [data, list, rec, Svc];
}

// @ts-ignore // expect: TS-IGNORE
const broken: number = 'x';

export async function d(raw: string) {
  try {
    await fetch('/x');
  } catch { // expect: SILENT-CATCH
  }
  try {
    await fetch('/y');
  } catch (err) { // expect: SILENT-CATCH
    return null;
  }
  await fetch('/z').catch(() => {}); // expect: SILENT-CATCH
  await fetch('/z').catch(() => null); // expect: SILENT-CATCH
  const parsed = JSON.parse(raw); // expect: JSON-NO-ZOD
  return [parsed, broken, User];
}
