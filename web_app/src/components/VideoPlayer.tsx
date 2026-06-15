'use client';

import { useEffect, useMemo, useRef } from 'react';
import styles from '../app/learn/[courseId]/page.module.css';

declare global {
  interface Window {
    YT?: {
      Player: new (
        elementId: string,
        options: {
          videoId: string;
          playerVars?: Record<string, number | string>;
          events?: {
            onReady?: (event: { target: YTPlayer }) => void;
            onStateChange?: (event: { data: number; target: YTPlayer }) => void;
          };
        }
      ) => YTPlayer;
      PlayerState?: {
        PLAYING: number;
        PAUSED: number;
        ENDED: number;
      };
    };
    onYouTubeIframeAPIReady?: () => void;
  }
}

interface YTPlayer {
  playVideo: () => void;
  pauseVideo: () => void;
  getCurrentTime: () => number;
  getDuration: () => number;
  destroy: () => void;
}

interface VideoPlayerProps {
  videoUrl: string;
  title: string;
  lessonId: string;
  startAt?: number;
  onProgress: (position: number, duration: number) => void;
  onComplete?: () => void;
}

function getYoutubeVideoId(url: string): string | null {
  try {
    if (url.includes('youtube.com/watch')) {
      return new URL(url).searchParams.get('v');
    }
    if (url.includes('youtu.be/')) {
      return url.split('youtu.be/')[1]?.split('?')[0] || null;
    }
    if (url.includes('youtube.com/embed/')) {
      return url.split('youtube.com/embed/')[1]?.split('?')[0] || null;
    }
  } catch {
    return null;
  }
  return null;
}

function loadYouTubeAPI(): Promise<void> {
  return new Promise((resolve) => {
    if (window.YT?.Player) {
      resolve();
      return;
    }

    const existing = document.getElementById('youtube-api-script');
    if (existing) {
      existing.addEventListener('load', () => resolve());
      return;
    }

    const tag = document.createElement('script');
    tag.id = 'youtube-api-script';
    tag.src = 'https://www.youtube.com/iframe_api';
    tag.onload = () => {
      window.onYouTubeIframeAPIReady = () => resolve();
    };
    document.body.appendChild(tag);
  });
}

export function VideoPlayer({
  videoUrl,
  title,
  lessonId,
  startAt = 0,
  onProgress,
  onComplete,
}: VideoPlayerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const htmlVideoRef = useRef<HTMLVideoElement>(null);
  const youtubeContainerId = useMemo(() => `youtube-player-${lessonId}`, [lessonId]);
  const ytPlayerRef = useRef<YTPlayer | null>(null);
  const progressIntervalRef = useRef<number | null>(null);
  const completedRef = useRef(false);
  const startAtRef = useRef(startAt);
  const onProgressRef = useRef(onProgress);
  const onCompleteRef = useRef(onComplete);

  const isYoutube =
    videoUrl.includes('youtube.com') ||
    videoUrl.includes('youtu.be');

  useEffect(() => {
    onProgressRef.current = onProgress;
    onCompleteRef.current = onComplete;
  }, [onProgress, onComplete]);

  useEffect(() => {
    completedRef.current = false;
  }, [lessonId]);

  useEffect(() => {
    startAtRef.current = startAt;
  }, [startAt]);

  // HTML5 video progress tracking
  useEffect(() => {
    if (isYoutube) return;

    const video = htmlVideoRef.current;
    if (!video) return;

    if (startAtRef.current > 0) {
      video.currentTime = startAtRef.current;
    }

    const onTimeUpdate = () => {
      const position = video.currentTime || 0;
      const duration = video.duration || 0;
      onProgressRef.current(position, duration);

      if (duration > 0 && position / duration >= 0.95 && !completedRef.current) {
        completedRef.current = true;
        onCompleteRef.current?.();
      }
    };

    const onEnded = () => {
      completedRef.current = true;
      onCompleteRef.current?.();
    };

    video.addEventListener('timeupdate', onTimeUpdate);
    video.addEventListener('ended', onEnded);

    return () => {
      video.removeEventListener('timeupdate', onTimeUpdate);
      video.removeEventListener('ended', onEnded);
    };
  }, [isYoutube, lessonId, videoUrl]);

  // YouTube progress tracking
  useEffect(() => {
    if (!isYoutube) return;

    const videoId = getYoutubeVideoId(videoUrl);
    if (!videoId) return;

    let cancelled = false;

    loadYouTubeAPI().then(() => {
      if (cancelled || !window.YT?.Player || !containerRef.current) return;

      const player = new window.YT.Player(youtubeContainerId, {
        videoId,
        playerVars: {
          autoplay: 0,
          start: Math.floor(startAtRef.current),
          rel: 0,
          modestbranding: 1,
        },
        events: {
          onReady: () => {
            if (progressIntervalRef.current) {
              window.clearInterval(progressIntervalRef.current);
            }
            progressIntervalRef.current = window.setInterval(() => {
              const position = player.getCurrentTime?.() || 0;
              const duration = player.getDuration?.() || 0;
              onProgressRef.current(position, duration);

              if (
                duration > 0 &&
                position / duration >= 0.95 &&
                !completedRef.current
              ) {
                completedRef.current = true;
                onCompleteRef.current?.();
              }
            }, 3000);
          },
          onStateChange: (event) => {
            if (event.data === window.YT?.PlayerState?.ENDED && !completedRef.current) {
              completedRef.current = true;
              onCompleteRef.current?.();
            }
          },
        },
      });

      ytPlayerRef.current = player;
    });

    return () => {
      cancelled = true;
      if (progressIntervalRef.current) {
        window.clearInterval(progressIntervalRef.current);
      }
      ytPlayerRef.current?.destroy?.();
    };
  }, [isYoutube, videoUrl, youtubeContainerId]);

  if (isYoutube) {
    return (
      <div ref={containerRef} className={styles.videoContainer}>
        <div id={youtubeContainerId} className={styles.iframePlayer} />
      </div>
    );
  }

  return (
    <div className={styles.videoContainer}>
      <video
        ref={htmlVideoRef}
        src={videoUrl}
        controls
        preload="metadata"
        className={styles.htmlVideo}
        title={title}
      />
    </div>
  );
}
