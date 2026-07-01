'use client';

import { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(ScrollTrigger);
}

export function useFadeIn<T extends HTMLElement>(delay = 0) {
  const ref = useRef<T>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    gsap.fromTo(
      el,
      { opacity: 0, y: 24 },
      {
        opacity: 1,
        y: 0,
        duration: 0.7,
        delay,
        ease: 'power3.out',
        scrollTrigger: {
          trigger: el,
          start: 'top 85%',
          toggleActions: 'play none none none',
        },
      }
    );

    return () => {
      ScrollTrigger.getAll().forEach((st) => {
        if (st.trigger === el) st.kill();
      });
    };
  }, [delay]);

  return ref;
}

export function useStagger<T extends HTMLElement>(childSelector: string) {
  const ref = useRef<T>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const children = el.querySelectorAll(childSelector);
    if (children.length === 0) return;

    gsap.fromTo(
      children,
      { opacity: 0, y: 28 },
      {
        opacity: 1,
        y: 0,
        duration: 0.6,
        stagger: 0.08,
        ease: 'power3.out',
        scrollTrigger: {
          trigger: el,
          start: 'top 80%',
          toggleActions: 'play none none none',
        },
      }
    );

    return () => {
      ScrollTrigger.getAll().forEach((st) => {
        if (st.trigger === el) st.kill();
      });
    };
  }, [childSelector]);

  return ref;
}

export function usePageTransition() {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    gsap.fromTo(
      el,
      { opacity: 0, y: 12, scale: 0.995 },
      { opacity: 1, y: 0, scale: 1, duration: 0.5, ease: 'power2.out' }
    );
  }, []);

  return ref;
}

export function animateIn(
  selector: string,
  options: { y?: number; delay?: number; stagger?: number; duration?: number } = {}
) {
  if (typeof window === 'undefined') return;

  const elements = document.querySelectorAll(selector);
  if (elements.length === 0) return;

  gsap.fromTo(
    elements,
    { opacity: 0, y: options.y ?? 24 },
    {
      opacity: 1,
      y: 0,
      duration: options.duration ?? 0.6,
      delay: options.delay ?? 0,
      stagger: options.stagger ?? 0,
      ease: 'power3.out',
      scrollTrigger: {
        trigger: elements[0],
        start: 'top 85%',
        toggleActions: 'play none none none',
      },
    }
  );
}

export function useSlideFadeIn(delay = 0) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    gsap.fromTo(el, { opacity: 0, y: 20 }, { opacity: 1, y: 0, duration: 0.8, delay, ease: 'power3.out' });
    return () => { gsap.killTweensOf(el); };
  }, [delay]);

  return ref;
}

export function useScaleIn(delay = 0) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    gsap.fromTo(el, { opacity: 0, scale: 0.8 }, { opacity: 1, scale: 1, duration: 0.6, delay, ease: 'back.out(1.7)' });
    return () => { gsap.killTweensOf(el); };
  }, [delay]);

  return ref;
}

export function useStaggeredList(count: number, stagger = 0.05) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const children = el.children;
    if (!children.length) return;
    gsap.fromTo(children, { opacity: 0, y: 20 }, { opacity: 1, y: 0, duration: 0.5, stagger, ease: 'power3.out', delay: 0.1 });
    return () => { gsap.killTweensOf(children); };
  }, [count, stagger]);

  return ref;
}
