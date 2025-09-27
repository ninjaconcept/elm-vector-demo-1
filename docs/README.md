# 3D Vector Animations Demo

**[🌐 Live Demo](https://ninjaconcept.github.io/elm-vector-demo-1/)**

A fun demo exploring pure SVG rendering with four animated 3D wave grids (5,000+ polygons) and interactive rotation.

## Features

- **Four unique wave animations**: Classic ripples, X-Y grid waves, spiral patterns, and complex interference
- **Responsive layout**: Adapts from 2x2 grid on desktop to single column on mobile
- **Interactive 3D rotation**: Mouse/touch controls with smooth interpolation
- **Enhanced color mapping**: 67% spectrum range with dynamic hue cycling
- **Smooth animation**: Real-time 3D projection with z-depth sorting

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