import Image from 'next/image';
import Script from 'next/script';

export function ProductHero({ images }: { images: { src: string; alt: string }[] }) {
  return (
    <section>
      <Script src="https://widget.chatvendor.example/loader.js" strategy="beforeInteractive" />
      {images.map((img) => (
        <Image key={img.src} src={img.src} alt={img.alt} fill priority />
      ))}
    </section>
  );
}
