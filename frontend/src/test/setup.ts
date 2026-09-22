import '@testing-library/jest-dom/vitest'

// jsdom has no matchMedia, and Ant Design's responsive components ask for one.
// Nothing here is under test at a particular viewport, so every query reports
// "no match" and components take their default, widest layout.
window.matchMedia ??= (query: string): MediaQueryList =>
  ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }) as MediaQueryList
