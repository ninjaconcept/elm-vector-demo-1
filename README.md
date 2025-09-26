# 3D Vector Animations in Elm

A modernized Elm demo showcasing animated 3D grid visualizations with rotating perspectives and wave effects.

**[🌐 Live Demo](https://ninjaconcept.github.io/elm-vector-demo-1/)**

## Features

- Animated 3D wave grid with mathematical wave functions
- Rotating camera perspective
- Real-time color-mapped height visualization
- Multiple synchronized animation layers

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

## Project Structure

- `src/Main.elm` - Main application with 3D math and rendering
- `elm.json` - Project dependencies and configuration

## Notes

This project has been updated from Elm 0.18 to 0.19.1 with:
- Removed deprecated OpenSolid geometry library
- Custom 3D projection and rotation mathematics
- Modern Elm Browser.element architecture
- Updated Time and animation handling
