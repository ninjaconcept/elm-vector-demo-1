# 3D Vector Animations in Elm

A fun Elm demo exploring what's possible with pure SVG rendering. Features four animated 3D wave grids (5,000+ SVG polygons) with interactive rotation and mathematical wave functions.

[![3D Vector Animation Demo](demo-screenshot.png?v=2)](https://ninjaconcept.github.io/elm-vector-demo-1/)

**[🌐 Live Demo](https://ninjaconcept.github.io/elm-vector-demo-1/)**

## Features

- **Four unique wave animations**: Classic ripples, X-Y grid waves, spiral patterns, and complex interference
- **Interactive 3D rotation**: Mouse controls with smooth interpolation
- **Vibrant color mapping**: Height-based spectrum with dynamic hue cycling
- **Smooth animation**: Real-time 3D projection with z-depth sorting
- **Mathematical precision**: Custom wave functions with time-based animation
- **Pure SVG rendering**: 5,000+ animated polygons testing browser SVG performance

## Technical Details

### Wave Functions
- **Classic Ripples**: Expanding circular waves with amplitude decay
- **X-Y Grid Waves**: Orthogonal sine wave interference patterns
- **Spiral Waves**: Radial waves with angular offset creating spiral motion
- **Complex Interference**: Multi-source wave interference with time modulation

## Setup

1. **Install Elm** (if not already installed):
   ```bash
   npm install -g elm
   ```

2. **Install dependencies**:
   ```bash
   elm install
   ```

3. **Start development server**:
   ```bash
   elm reactor
   ```

4. **View the demo**:
   - Open http://localhost:8000 in your browser
   - Navigate to `src/Main.elm` to see the animation

5. **Build for production**:
   ```bash
   ./build-demo.sh
   ```

## Project Structure

- `src/Main.elm` - Main application with 3D math and rendering logic
- `docs/` - GitHub Pages deployment with optimized build
- `elm.json` - Project dependencies and configuration
- `build-demo.sh` - Production build script for GitHub Pages

## Browser Compatibility

Optimized for modern browsers with SVG and CSS Grid support:
- Chrome 57+, Firefox 52+, Safari 10.1+, Edge 16+
- Mobile Safari iOS 10.3+, Chrome Mobile 57+

## Notes

This project has been modernized from Elm 0.18 to 0.19.1 with:
- Removed deprecated OpenSolid geometry library
- Custom 3D projection and rotation mathematics
- Modern Elm Browser.element architecture
- Updated Time and animation handling
- Enhanced color systems
