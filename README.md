# SkeuoSimControls

**SkeuoSimControls** is a custom component library for [Lazarus](https://www.lazarus-ide.org/) / Free Pascal, specifically designed for building realistic, *skeuomorphic* user interfaces (UI). 


<img width="900" height="445" alt="image" src="https://github.com/user-attachments/assets/82a78baf-9b31-448a-9b37-d1bc158bfb9d" />



Built on top of the **BGRABitmap** graphic engine, these components offer high-quality, anti-aliased rendering perfectly suited for simulation software, avionics dashboards, industrial control panels, and audio software interfaces (Virtual Instruments/Mixers).

## 🚀 Key Features
- **20+ Interactive Components**: Ranging from simple switches to dynamic radar screens and oscilloscopes.
- **High-Quality Rendering**: Utilizes BGRABitmap for smooth gradients, drop shadows, glowing elements, and glass reflections.
- **Highly Customizable**: Tweak colors, value ranges, and component states directly through the Lazarus *Object Inspector*.
- **Self-Contained**: Rendering is purely drawn via mathematical code and BGRABitmap (no reliance on external bitmap assets for UI logic).

## 🎛️ Component List (SkeuoSim Palette)
- **Indicators & Displays**: `TLEDIndicator`, `TSevenSegment`, `TSimLedBarGraph`, `TSimLcdDisplay`
- **Switches & Buttons**: `TSimToggleSwitch`, `TSimPushButton`, `TSimSafetySwitch`, `TSimMatrixPad`
- **Dials & Sliders**: `TKnob`, `TSimFader`, `TSimSelectorSwitch`, `TSimThrottleLever`, `TSimJoystick`
- **Gauges**: `TCircularGauge`, `TLinearGauge`, `TVuMeter`, `TCompass`, `TAviatorGauge`
- **Advanced Screens**: `TSimOscilloscope`, `TSimRadarScreen`
- **Misc**: `TSimGroupBox`, `TSimAudioJack`

## 📦 Prerequisites
1. Lazarus IDE (Latest version recommended).
2. **BGRABitmap** package (Easily installable via the *Online Package Manager* / OPM in Lazarus).

## 🛠️ Installation Guide
1. Clone or download this repository.
2. Open Lazarus IDE.
3. Go to **Package** -> **Open Package File (.lpk)**.
4. Select the `SkeuoSimControls.lpk` file from the `source` folder.
5. Click **Compile**. Ensure the compilation is successful without errors.
6. Click **Install** and allow Lazarus to rebuild.
7. Once Lazarus restarts, you will find a new tab named **"SkeuoSim"** in your *Component Palette*.

## 📜 License
MIT License
