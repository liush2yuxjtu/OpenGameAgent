import type { FontArtifactRef } from '@hypit/hypit/media';
import type { Timeline } from '@hypit/hypit/timeline';
import type { CanvasSpace } from '@hypit/hypit/spatial';
import type { TemporalInstant, TemporalWindow } from '@hypit/hypit/temporal';
export type Message = {
    id: string;
    sender: string;
    text: string;
    side: 'left' | 'right';
    at: TemporalInstant;
};
export type ChatOptions = {
    id: string;
    title: string;
    entranceFrames: number;
};
export declare function renderChat(timeline: Timeline, canvas: CanvasSpace, window: TemporalWindow, font: FontArtifactRef, messages: readonly Message[], options: ChatOptions, image: FontArtifactRef['sources'][number]['artifact']): import("@hypit/hypit/composition").VisualTrack;
