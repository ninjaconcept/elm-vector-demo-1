# 3D Vector Animations Demo

**[🌐 Live Demo](https://ninjaconcept.github.io/elm-vector-demo-1/)**

An interactive demo showcasing four distinct animated 3D grid visualizations with responsive design and vibrant color spectrums.

## Features

- **Four unique wave animations**: Classic ripples, X-Y grid waves, spiral patterns, and complex interference
- **Responsive layout**: Adapts from 2x2 grid on desktop to single column on mobile
- **Interactive 3D rotation**: Mouse/touch controls with smooth interpolation
- **Enhanced color mapping**: 67% spectrum range with dynamic hue cycling
- **Real-time rendering**: 30fps 3D projection with z-depth sorting

## Technical Highlights

### Wave Functions
- **Classic Ripples**: Expanding circular waves with amplitude decay
- **X-Y Grid Waves**: Orthogonal sine wave interference patterns
- **Spiral Waves**: Radial waves with angular offset creating spiral motion
- **Complex Interference**: Multi-source wave interference with time modulation

### Implementation
Built with modern Elm 0.19.1 featuring:
- Custom 3D projection and rotation mathematics
- Browser.element architecture with smooth animation subscriptions
- CSS Grid with media queries for responsive layout
- HSL color space optimization for vibrant visuals

---

**Source code**: [GitHub Repository](https://github.com/ninjaconcept/elm-vector-demo-1)