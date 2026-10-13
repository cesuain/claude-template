import { Skeleton } from '@/components/ui/skeleton';

export function Banner({ name }: { name: string }) {
  return (
    <section>
      <p>Sign in as Admin to continue!</p>
      <p className="text-sm">Pick any option as you like</p>
      <p>
        Signed in as Guest. Choose any plan you like
      </p>
      {name ? <span>{name}</span> : <Skeleton className="h-5 w-24" />}
    </section>
  );
}
