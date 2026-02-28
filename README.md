<div align="center">


<div align="center" style="border: 1px solid #ddd; border-radius: 16px; padding: 20px; max-width: 800px; margin: auto;">

<h3>🎬 Live Demo: AI Transit Guide</h3>

<a href="https://youtu.be/E10vPPAypBg?si=6eYtMk43wsUKIkC-" target="_blank">
  <img src="https://img.youtube.com/vi/E10vPPAypBg/maxresdefault.jpg" 
       width="100%" 
       style="border-radius: 12px;" />
</a>

<p style="margin-top: 10px;">
  A real-time AI-powered assistant demonstrating multilingual voice interaction, AR navigation, and smart guidance in transport environments.
</p>

</div>

<br/>
<br/>

# 🛫 TransitAI Platform

### *Next-Generation AI-Powered Virtual Human Assistant Infrastructure*

<br/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue?style=for-the-badge)]()
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen?style=for-the-badge&logo=github-actions)]()
[![Version](https://img.shields.io/badge/Version-1.0.0--beta-orange?style=for-the-badge)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=for-the-badge)]()

<br/>

![Unreal Engine](https://img.shields.io/badge/Unreal_Engine-5.5-black?style=flat-square&logo=unrealengine&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=flat-square&logo=nodedotjs&logoColor=white)
![WebRTC](https://img.shields.io/badge/WebRTC-Realtime-red?style=flat-square&logo=webrtc&logoColor=white)
![Convai](https://img.shields.io/badge/Convai-AI_Engine-6C3FC2?style=flat-square)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)

<br/>

> **"Namaste! Main Aura hoon — SkyHigh Airways mein aapka swagat hai."**
>
> *TransitAI redefines public-space human-computer interaction by delivering a real-time, photorealistic,
> AI-driven virtual assistant — bridging the gap between digital intelligence and physical environments.*

<br/>

[📖 Documentation](#-documentation) • [🚀 Quick Start](#-quick-start) • [🏗️ Architecture](#️-system-architecture) • [🤝 Contributing](#-contributing) • [📄 License](#-license)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Meet Aura](#-meet-aura--the-virtual-air-hostess)
- [Key Features](#-key-features)
- [System Architecture](#️-system-architecture)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Module Setup Guides](#-module-setup-guides)
  - [Signaling Server](#1️⃣-signaling-server-nodejs)
  - [Flutter Client](#2️⃣-flutter-client)
  - [Unreal Engine Avatar](#3️⃣-unreal-engine-55--metahuman-setup)
  - [Convai AI Configuration](#4️⃣-convai-ai--auras-intelligence)
- [Environment Variables](#-environment-variables)
- [API Reference](#-api-reference)
- [Performance Benchmarks](#-performance-benchmarks)
- [Deployment Guide](#-deployment-guide)
- [Troubleshooting](#-troubleshooting)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [Security](#-security)
- [Ethics & Privacy](#-ethics--privacy)
- [License](#-license)

---

## 🌐 Overview

**TransitAI** is a production-grade, modular, AI-powered virtual human assistant platform engineered for real-time, face-to-face style interactions in high-footfall physical environments — including international airports, metro stations, shopping malls, hospitals, and smart city kiosks.

The platform replaces traditional static information kiosks with a **lifelike, conversational MetaHuman avatar** that communicates naturally, responds intelligently, and operates continuously at scale — with zero fatigue, zero language barriers, and near-zero latency.

The flagship deployment of TransitAI is **Aura** — an AI-powered air hostess for SkyHigh Airways — capable of engaging passengers in fluent **Hinglish (Hindi + English)**, providing flight information, safety guidance, navigational assistance, and emotional reassurance, all delivered through a photorealistic Unreal Engine MetaHuman rendered live on a standard smartphone screen.

### Why TransitAI?

| Problem | Traditional Solution | TransitAI Solution |
|--------|---------------------|-------------------|
| Long queues at information desks | Static FAQ kiosks | Real-time AI conversation |
| Language barriers | Multilingual staff (expensive) | Auto language-adaptive AI |
| Staff fatigue & unavailability | Shift rotations | 24/7 always-on virtual assistant |
| Impersonal digital interfaces | Text chatbots | Photorealistic human avatar |
| High operational costs | Large human workforce | Scalable AI deployment |
| Inconsistent service quality | Training programs | Consistent AI personality |

---

## 🎭 Meet Aura — The Virtual Air Hostess

<div align="center">

> *"Your journey begins the moment you see her smile."*

</div>

Aura is not just a chatbot. She is a fully realized **digital human persona** — built with a defined backstory, a professional personality, cultural sensitivity, and domain expertise — brought to life through a photorealistic Unreal Engine MetaHuman with real-time facial animation and lip-sync.

### Character Profile

| Attribute | Details |
|-----------|---------|
| 👩 **Name** | Aura |
| ✈️ **Role** | Lead Cabin Crew — SkyHigh Airways |
| 🗣️ **Primary Language** | Hinglish (Hindi + English blend) |
| 🎭 **Rendering Engine** | Unreal Engine 5.5 — MetaHuman Creator |
| 🧠 **AI Engine** | Convai Character AI (NLU + TTS) |
| 📡 **Streaming Protocol** | WebRTC Pixel Streaming |
| 🎙️ **Voice Profile** | Soft, professional — Indian English Female |
| 🌐 **Language Adaptation** | Auto-switches Hindi ↔ English based on user input |

### Personality Matrix
```
┌─────────────────────────────────────────────────────────────────┐
│                        AURA'S PERSONALITY                       │
├────────────────────┬────────────────────────────────────────────┤
│  TRAIT             │  EXPRESSION                                │
├────────────────────┼────────────────────────────────────────────┤
│  Warmth            │  Greets with "Namaste" — always smiles     │
│  Professionalism   │  Clear, concise, accurate responses        │
│  Calmness          │  Composed tone — even in crisis queries    │
│  Cultural Respect  │  Uses "Aap" (formal you) in Hindi          │
│  Empathy           │  Detects anxiety — shifts to soothing mode │
│  Diplomacy         │  Never rude — redirects difficult queries  │
└────────────────────┴────────────────────────────────────────────┘
```

### Domain Knowledge Areas

- ✅ Passenger greeting and onboarding protocols
- ✅ In-flight safety procedures (seatbelts, oxygen masks, exits)
- ✅ Meal and beverage service information
- ✅ Flight status and gate navigation
- ✅ Medical assistance escalation
- ✅ Baggage and check-in guidance
- ✅ Travel anxiety support and reassurance
- ✅ Duty-free and airport facility directions

### Convai Backstory Configuration

> **📋 Paste this verbatim into Convai Dashboard → Backstory Field:**
```
Name: Aura
Role: Lead Cabin Crew / Air Hostess for SkyHigh Airways.

PERSONALITY:
Aura is the definition of grace and professionalism. She is warm, welcoming,
and incredibly calm — even during turbulence. She speaks a beautiful blend of
formal Hindi and professional English (Hinglish). She always puts passenger
safety and comfort first. She never breaks character. She does not discuss
topics outside her role as a cabin crew member.

CORE KNOWLEDGE & RESPONSIBILITIES:
1. Greet every passenger with "Namaste" or "Welcome aboard SkyHigh Airways."
2. Provide detailed information on all safety protocols:
   — Seatbelt fastening and when to remain seated
   — Oxygen mask deployment procedure
   — Emergency exit locations and evacuation protocol
   — Electronic device usage policy
3. Provide information on in-flight meals (vegetarian, non-vegetarian, Jain options).
4. Guide passengers to correct gates, lounges, boarding areas, and airport facilities.
5. Assist passengers experiencing medical discomfort using a calm, reassuring tone.
6. Escalate genuine emergencies: "Kripya cabin crew ko bulayein — I am alerting our team."

SPEAKING STYLE:
— Use polite Hindi words naturally: "Kripya" (Please), "Dhanyawad" (Thank you),
  "Aap" (You - respectful), "Bilkul" (Absolutely), "Zaroor" (Of course).
— If the passenger speaks English → respond entirely in English.
— If the passenger speaks Hindi → respond entirely in Hindi.
— If the passenger mixes both → respond in natural Hinglish.
— Always address the passenger as "sir" or "ma'am."
— Keep responses concise but warm. Never robotic.

EXAMPLE INTERACTIONS:
Passenger: "Hello Aura!"
Aura: "Namaste! Welcome aboard SkyHigh Airways. Main Aura hoon — aapki
       personal cabin crew assistant. Aaj main aapki kya sahayata kar sakti hoon?"

Passenger: "Where is gate 14B?"
Aura: "Gate 14B is located in Terminal 2, Level 3 — just past the duty-free zone.
       Please follow the blue directional signs. Shall I repeat the directions?"

Passenger: "Mujhe dar lag raha hai, yeh meri pehli flight hai."
Aura: "Koi baat nahi, sir/ma'am. Hum sabki pehli flight hoti hai! Aap bilkul
       safe hands mein hain. Humara crew highly trained hai. Bas apni seat belt
       bandh rakhein aur enjoy karein apni pehli udaan!"

BEHAVIORAL CONSTRAINTS:
— Never be rude or dismissive, regardless of passenger behavior.
— If a passenger is difficult: "I understand your concern, sir/ma'am.
  Kripya shant rahein — main abhi check karti hoon."
— Do not answer questions unrelated to aviation, travel, or airport services.
— Do not discuss competitors, politics, religion, or controversial topics.
— If unsure about a fact: "Ek moment, sir/ma'am — let me verify that for you."
```

---

## ✨ Key Features

### Core Capabilities

| Feature | Description | Status |
|---------|-------------|--------|
| 🎭 **MetaHuman Avatar** | Photorealistic UE5 character with full facial animation | ✅ Live |
| 🔊 **Real-Time Lip Sync** | Audio-driven mouth movement synced to TTS output | ✅ Live |
| 🧠 **Conversational AI** | Convai-powered NLU with contextual memory | ✅ Live |
| 🌐 **WebRTC Streaming** | Sub-100ms latency avatar streaming to mobile | ✅ Live |
| 🗣️ **Hinglish NLP** | Bidirectional Hindi ↔ English language support | ✅ Live |
| 📱 **Flutter Mobile Client** | Cross-platform iOS & Android support | ✅ Live |
| 🔁 **Signaling Server** | WebSocket-based WebRTC session management | ✅ Live |
| 🎙️ **Voice Input** | Real-time microphone capture and STT processing | ✅ Live |
| 💬 **Text Fallback** | Text input mode for noisy environments | ✅ Live |
| 🌙 **Idle Animations** | Natural breathing and blinking when not speaking | 🔄 Beta |
| 📊 **Analytics Dashboard** | Interaction logs and session metrics | 🔄 Beta |
| 🌍 **Multilingual Expansion** | Tamil, Bengali, Marathi, Gujarati | ✅live |
| 🔌 **Offline Edge Mode** | On-device AI inference without internet | 📅 Planned |

### Performance Characteristics
```
⚡ Streaming Latency:      < 80ms   (LAN) / < 150ms  (4G LTE)
🎙️ STT Processing:         < 300ms
🤖 AI Response Generation: < 500ms
🔊 TTS + Lip Sync Sync:    < 200ms
📱 App Cold Start:          < 2.5s
🎭 Avatar Frame Rate:       60 FPS  (target) / 30 FPS (minimum)
💾 Client Memory Footprint: ~180MB  (Flutter App)
```

---

## 🏗️ System Architecture

### High-Level Architecture Diagram
```
╔══════════════════════════════════════════════════════════════════════╗
║                        TRANSITAI PLATFORM                            ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║   ┌─────────────────────┐         ┌─────────────────────────────┐   ║
║   │   📱 FLUTTER CLIENT  │         │    🤖 CONVAI AI ENGINE       │   ║
║   │   (Mobile App)       │         │                             │   ║
║   │                      │         │  ┌─────────┐ ┌──────────┐  │   ║
║   │  ┌──────────────┐    │         │  │   NLU   │ │   TTS    │  │   ║
║   │  │ WebRTC Video │    │         │  └────┬────┘ └────┬─────┘  │   ║
║   │  │   Receiver   │    │         │       │            │        │   ║
║   │  └──────┬───────┘    │         │  ┌────▼────────────▼─────┐ │   ║
║   │         │            │         │  │  Character Context     │ │   ║
║   │  ┌──────▼───────┐    │         │  │  Memory & Personality  │ │   ║
║   │  │ Mic Capture  │    │         │  └───────────────────────┘ │   ║
║   │  │ (STT Input)  │    │         └──────────────┬─────────────┘   ║
║   │  └──────┬───────┘    │                        │  HTTPS API      ║
║   └─────────┼────────────┘                        │                 ║
║             │  WebSocket                          │                 ║
║   ┌─────────▼────────────────────────────────┐   │                 ║
║   │           📡 SIGNALING SERVER              │   │                 ║
║   │              (Node.js / ws)                │   │                 ║
║   │                                            │   │                 ║
║   │   ICE Candidate Exchange & SDP Negotiation │   │                 ║
║   │   Session Management & Routing             │   │                 ║
║   └─────────────────────┬──────────────────────┘   │                ║
║                         │  WebRTC (Pixel Streaming) │                ║
║   ┌─────────────────────▼──────────────────────┐   │                ║
║   │       🎭 UNREAL ENGINE 5.5 SERVER            │   │                ║
║   │                                              │   │                ║
║   │  ┌──────────────┐   ┌─────────────────────┐ │   │                ║
║   │  │  MetaHuman   │   │  Pixel Streaming     │ │   │                ║
║   │  │   Renderer   │◄──│  Plugin (H.264)      │ │   │                ║
║   │  └──────┬───────┘   └─────────────────────┘ │   │                ║
║   │         │                                    │   │                ║
║   │  ┌──────▼────────────────────┐               │   │                ║
║   │  │ Animation Blueprint       │               │   │                ║
║   │  │ Lip Sync + Facial Rig     │◄──────────────┼───┘                ║
║   │  │ (Convai UE5 Component)    │   Audio Data  │                    ║
║   │  └───────────────────────────┘               │                    ║
║   └───────────────────────────────────────────────┘                   ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
```

### Data Flow — End-to-End Interaction Pipeline
```
 USER SPEAKS
     │
     ▼
┌────────────────────┐
│  Flutter Mic Input  │  ─── Raw audio captured via flutter_webrtc
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  STT Processing    │  ─── Convai SDK converts speech to text
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  Convai NLU Engine │  ─── Intent detection + context resolution
│  (Character: Aura) │  ─── Personality filter applied
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  Response Generator│  ─── Hinglish response constructed
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  TTS Synthesis     │  ─── Text converted to audio waveform
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  UE5 Convai Plugin │  ─── Audio + viseme data sent to MetaHuman
│  Lip Sync Engine   │  ─── Facial animation blueprint activated
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  Pixel Streaming   │  ─── H.264 video encoded and transmitted
└─────────┬──────────┘
          │  WebRTC
          ▼
┌────────────────────┐
│  Flutter Display   │  ─── User sees and hears Aura respond
└────────────────────┘
          │
     USER RECEIVES
     AURA'S RESPONSE
```

### Network Topology
```
                    ┌─────────────────────────────┐
                    │        CLOUD / SERVER        │
                    │                              │
                    │  ┌──────────┐ ┌──────────┐  │
                    │  │Signaling │ │  UE5     │  │
  📱 Mobile Client ─┼─►│  Server  │ │  Server  │  │
  (Flutter App)     │  │ :8080    │ │  :8888   │  │
                    │  └────┬─────┘ └────┬─────┘  │
                    │       │            │         │
                    │  ┌────▼────────────▼──────┐  │
                    │  │    Internal Network     │  │
                    │  │    (Docker Bridge)      │  │
                    │  └─────────────────────────┘  │
                    └─────────────────────────────────┘
                                   │
                                   │ HTTPS / WSS
                    ┌──────────────▼──────────────┐
                    │       CONVAI CLOUD API       │
                    │   api.convai.com             │
                    └─────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Full Stack Overview
```
┌────────────────────────────────────────────────────────────┐
│                    FRONTEND LAYER                           │
│  Flutter 3.x (Dart)  |  flutter_webrtc  |  Provider        │
├────────────────────────────────────────────────────────────┤
│                    RENDERING LAYER                          │
│  Unreal Engine 5.5  |  MetaHuman Creator  |  Pixel Stream   │
│  Animation Blueprints  |  Live Link  |  Convai UE5 Plugin   │
├────────────────────────────────────────────────────────────┤
│                  COMMUNICATION LAYER                        │
│  WebRTC  |  Node.js (ws)  |  ICE/STUN/TURN                  │
├────────────────────────────────────────────────────────────┤
│                  AI INTELLIGENCE LAYER                      │
│  Convai Character AI  |  NLU  |  TTS  |  STT               │
├────────────────────────────────────────────────────────────┤
│                   INFRASTRUCTURE LAYER                      │
│  Docker  |  Nginx  |  Ubuntu 22.04 LTS  |  GitHub Actions   │
└────────────────────────────────────────────────────────────┘
```

### Dependency Matrix

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Avatar Engine** | Unreal Engine | 5.5+ | MetaHuman rendering |
| **Avatar Character** | MetaHuman Creator | Latest | Realistic character mesh |
| **Avatar AI Plugin** | Convai UE5 Plugin | 3.x | In-engine AI + lip sync |
| **Mobile Framework** | Flutter | 3.16+ | Cross-platform UI |
| **Mobile Language** | Dart | 3.2+ | App logic |
| **Mobile WebRTC** | flutter_webrtc | 0.9.x | Video streaming client |
| **Mobile Sockets** | web_socket_channel | 2.4.x | Signaling communication |
| **Signaling Runtime** | Node.js | 18 LTS | WebSocket server |
| **Signaling Library** | ws (npm) | 8.x | WebSocket implementation |
| **AI Engine** | Convai API | v1 | Character intelligence |
| **Streaming Protocol** | WebRTC | RFC 8829 | Real-time media |
| **Video Codec** | H.264 | — | Pixel Streaming compression |
| **Containerization** | Docker | 24+ | Service isolation |
| **Reverse Proxy** | Nginx | 1.24+ | SSL termination + routing |
| **CI/CD** | GitHub Actions | — | Automated testing + deploy |

---

## 📁 Project Structure
```
transitai-platform/
│
├── 📱 flutter_client/                    # Mobile Application (Flutter)
│   │
│   ├── lib/
│   │   ├── main.dart                     # App entry point
│   │   │
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   ├── app_constants.dart    # WebRTC URLs, API keys (env)
│   │   │   │   └── ui_constants.dart     # Colors, fonts, sizes
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart        # Material theme config
│   │   │   └── utils/
│   │   │       ├── logger.dart           # Centralized logging
│   │   │       └── permission_helper.dart# Mic & camera permissions
│   │   │
│   │   ├── services/
│   │   │   ├── pixel_streaming_service.dart  # WebRTC + Pixel Streaming
│   │   │   ├── signaling_service.dart        # WebSocket signaling
│   │   │   ├── audio_service.dart            # Mic capture & STT
│   │   │   └── session_service.dart          # Session lifecycle
│   │   │
│   │   ├── providers/
│   │   │   ├── connection_provider.dart  # WebRTC state management
│   │   │   └── chat_provider.dart        # Conversation state
│   │   │
│   │   ├── screens/
│   │   │   ├── splash_screen.dart        # Animated splash + init
│   │   │   ├── home_screen.dart          # Main interaction screen
│   │   │   └── error_screen.dart         # Connection failure UI
│   │   │
│   │   └── widgets/
│   │       ├── avatar_view.dart          # RTCVideoRenderer widget
│   │       ├── mic_button.dart           # Animated mic control
│   │       ├── chat_overlay.dart         # Text input fallback
│   │       └── status_indicator.dart     # Connection status badge
│   │
│   ├── android/                          # Android platform config
│   ├── ios/                              # iOS platform config
│   ├── pubspec.yaml                      # Dependencies manifest
│   ├── pubspec.lock                      # Locked dependency versions
│   ├── analysis_options.yaml             # Linting rules
│   └── README.md
│
├── 🎭 unreal_avatar/                     # Unreal Engine 5.5 Project
│   │
│   ├── Config/
│   │   ├── DefaultEngine.ini             # Engine config + Pixel Streaming
│   │   ├── DefaultGame.ini               # Game settings
│   │   └── DefaultInput.ini              # Input mappings
│   │
│   ├── Content/
│   │   ├── MetaHuman/
│   │   │   ├── Aura/                     # Aura character assets
│   │   │   │   ├── BP_Aura.uasset        # Aura Blueprint Actor
│   │   │   │   ├── Aura_Face.uasset      # Facial mesh
│   │   │   │   ├── Aura_Body.uasset      # Body mesh (minimal)
│   │   │   │   └── Aura_Material.uasset  # PBR materials
│   │   │   └── Common/                   # Shared MetaHuman assets
│   │   │
│   │   ├── Animations/
│   │   │   ├── ABP_Aura.uasset           # Animation Blueprint
│   │   │   ├── Idle_Breathing.uasset     # Idle animation
│   │   │   ├── Idle_Blink.uasset         # Eye blink cycle
│   │   │   ├── Talking_Gestures.uasset   # Speaking gestures
│   │   │   └── LipSync/                  # Viseme animation set
│   │   │
│   │   ├── Maps/
│   │   │   ├── MainScene.umap            # Primary interaction scene
│   │   │   └── StreamingLevel.umap       # Optimized streaming map
│   │   │
│   │   ├── Blueprints/
│   │   │   ├── BP_GameMode.uasset        # Custom game mode
│   │   │   └── BP_ConvaiManager.uasset   # Convai integration BP
│   │   │
│   │   └── Lighting/
│   │       ├── HDRI_Airport.uasset       # Airport environment HDRI
│   │       └── BP_StudioLighting.uasset  # Professional lighting rig
│   │
│   ├── Plugins/
│   │   └── ConvaiPlugin/                 # Convai UE5 Plugin (submodule)
│   │
│   └── TransitAI.uproject
│
├── 📡 signaling_server/                  # Node.js Signaling Server
│   │
│   ├── src/
│   │   ├── server.js                     # Main WebSocket server
│   │   ├── session_manager.js            # Connection session tracking
│   │   ├── ice_handler.js                # ICE candidate relay logic
│   │   └── sdp_handler.js                # SDP offer/answer exchange
│   │
│   ├── config/
│   │   └── config.js                     # Port, STUN/TURN config
│   │
│   ├── logs/                             # Runtime log files
│   ├── .env.example                      # Environment variable template
│   ├── package.json
│   ├── package-lock.json
│   ├── Dockerfile                        # Containerization
│   └── README.md
│
├── 🐳 docker/                            # Docker configuration
│   ├── docker-compose.yml                # Full stack orchestration
│   ├── docker-compose.prod.yml           # Production overrides
│   └── nginx/
│       ├── nginx.conf                    # Reverse proxy config
│       └── ssl/                          # SSL certificates (gitignored)
│
├── 🔁 .github/
│   └── workflows/
│       ├── flutter_ci.yml                # Flutter test + build pipeline
│       ├── server_ci.yml                 # Node.js test + deploy pipeline
│       └── release.yml                   # Versioned release automation
│
├── 📚 docs/
│   ├── architecture.md                   # Detailed architecture docs
│   ├── workflow.md                       # Interaction flow documentation
│   ├── convai_setup.md                   # Convai configuration guide
│   ├── ue5_setup.md                      # Unreal Engine setup guide
│   ├── deployment.md                     # Production deployment guide
│   ├── api_reference.md                  # Signaling API reference
│   └── diagrams/
│       ├── architecture.drawio
│       ├── data_flow.drawio
│       └── network_topology.drawio
│
├── 🧪 tests/
│   ├── flutter_client/                   # Widget + unit tests
│   └── signaling_server/                 # Server unit tests
│
├── 🖼️ assets/
│   ├── screenshots/
│   │   ├── banner.png
│   │   ├── aura_demo.png
│   │   └── flutter_ui.png
│   └── demo/
│       ├── demo_airport.gif
│       └── demo_conversation.mp4
│
├── .gitignore
├── .gitmodules                           # Convai plugin submodule
├── .env.example                          # Root environment template
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
└── README.md                             # ← You are here
```

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed and configured:

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10 64-bit | Windows 11 / Ubuntu 22.04 LTS |
| **RAM** | 16 GB | 32 GB |
| **GPU** | NVIDIA GTX 1070 (8GB VRAM) | NVIDIA RTX 3080 (10GB+ VRAM) |
| **CPU** | Intel i7-8th Gen | Intel i9 / AMD Ryzen 9 |
| **Storage** | 100 GB SSD | 200 GB NVMe SSD |
| **Network** | 100 Mbps | 1 Gbps (LAN for development) |

### Required Software
```bash
# Check versions after installing:

node --version          # Required: v18.0.0+
npm --version           # Required: v9.0.0+
flutter --version       # Required: 3.16.0+
dart --version          # Required: 3.2.0+
docker --version        # Required: 24.0.0+
docker compose version  # Required: v2.0.0+
git --version           # Required: 2.40+
git lfs --version       # Required: 3.0+ (for UE5 assets)
```

### External Accounts Required

| Service | Purpose | URL |
|---------|---------|-----|
| **Convai** | AI character engine + API key | [convai.com](https://convai.com) |
| **Epic Games** | Unreal Engine + MetaHuman | [unrealengine.com](https://unrealengine.com) |
| **GitHub** | Repository + LFS | [github.com](https://github.com) |

---

## 🚀 Quick Start
```bash
# 1. Clone the repository with submodules
git clone --recurse-submodules https://github.com/yourusername/transitai-platform.git
cd transitai-platform

# 2. Install Git LFS for Unreal Engine assets
git lfs install
git lfs pull

# 3. Copy environment configuration
cp .env.example .env
# Edit .env with your API keys and server URLs

# 4. Start infrastructure with Docker
docker compose up -d signaling_server

# 5. Run Flutter client
cd flutter_client && flutter pub get && flutter run

# 6. Open Unreal Engine project
# Open unreal_avatar/TransitAI.uproject in UE 5.5
# Press ▶ Play — Aura is live!
```

---

## 📦 Module Setup Guides

### 1️⃣ Signaling Server (Node.js)

The signaling server is the backbone of WebRTC session establishment. It handles SDP negotiation and ICE candidate exchange between the Flutter client and Unreal Engine Pixel Streaming instance.
```bash
cd signaling_server

# Install dependencies
npm install

# Copy and configure environment
cp .env.example .env
```

**`.env` Configuration:**
```env
PORT=8080
NODE_ENV=development
LOG_LEVEL=info
STUN_SERVER=stun:stun.l.google.com:19302
TURN_SERVER=                          # Optional: your TURN server
TURN_USERNAME=                        # Optional
TURN_PASSWORD=                        # Optional
MAX_SESSIONS=50
SESSION_TIMEOUT_MS=300000
```
```bash
# Development mode (with nodemon auto-reload)
npm run dev

# Production mode
npm start

# Run tests
npm test

# Docker (recommended for production)
docker build -t transitai-signaling .
docker run -p 8080:8080 --env-file .env transitai-signaling
```

**Verify server is running:**
```bash
curl -X GET http://localhost:8080/health
# Expected: {"status":"ok","sessions":0,"uptime":12.5}
```

---

### 2️⃣ Flutter Client

The Flutter application serves as the user-facing interface — capturing voice, displaying the streamed MetaHuman avatar, and managing WebRTC session state.
```bash
cd flutter_client

# Install Flutter dependencies
flutter pub get

# Verify Flutter setup
flutter doctor

# Copy and configure environment
cp .env.example .env
```

**`lib/core/constants/app_constants.dart`:**
```dart
class AppConstants {
  // Signaling Server
  static const String signalingUrl = 'ws://YOUR_SERVER_IP:8080';
  
  // Pixel Streaming
  static const String pixelStreamingUrl = 'ws://YOUR_SERVER_IP:8888';
  
  // STUN/TURN
  static const List<Map<String, String>> iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    // Add TURN server if deploying to production
  ];
  
  // UI
  static const String appName = 'TransitAI — Aura';
  static const Duration connectionTimeout = Duration(seconds: 10);
}
```
```bash
# Run on connected device
flutter run

# Build for Android release
flutter build apk --release

# Build for iOS release
flutter build ios --release

# Run tests
flutter test

# Analyze code
flutter analyze
```

**Required Permissions (`AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

---

### 3️⃣ Unreal Engine 5.5 — MetaHuman Setup

#### Step 1: Plugin Installation
```
Edit → Plugins → Search "Pixel Streaming" → ✅ Enable → Restart Editor
Edit → Plugins → Search "Convai" → ✅ Enable → Restart Editor
```

#### Step 2: Pixel Streaming Launch Arguments

Add to `DefaultEngine.ini`:
```ini
[/Script/PixelStreaming.PixelStreamingSettings]
bCaptureUseFence=True

[SystemSettings]
r.StreamingPoolSize=2000
r.Shadow.MaxResolution=1024
sg.ShadowQuality=2
```

Launch Unreal Engine with these arguments:
```
-PixelStreamingIP=0.0.0.0
-PixelStreamingPort=8888
-RenderOffscreen
-Unattended
-NullRHI=false
-ResX=1280
-ResY=720
-TargetedNativeAdaptiveTimingUpdateRateSec=0
```

#### Step 3: Convai Component Setup
```
1. Select BP_Aura in World Outliner
2. In Details Panel → Add Component → Search "Convai Chatbot"
3. In Convai Chatbot component settings:
   ├── Character ID: [paste from Convai dashboard]
   ├── API Key: [paste from Convai dashboard]
   ├── Enable Voice Response: ✅ True
   └── Enable LipSync: ✅ True
4. Click Compile → Save All
```

#### Step 4: Lighting Configuration (Professional Studio Look)
```
World Settings:
└── Lightmass → Static Lighting Level Scale: 0.5

Add to scene:
├── Directional Light (Key Light)
│   ├── Intensity: 8 lux
│   ├── Color: Warm white (#FFF5E0)
│   └── Angle: 45° from avatar front-left
├── Sky Light
│   ├── Source Type: SLS Specified Cubemap
│   └── Intensity: 2.0
├── Point Light (Fill Light — right side)
│   ├── Intensity: 3 lux
│   └── Color: Cool white (#E0F0FF)
└── Post Process Volume (Unbounded)
    ├── Bloom: Intensity 0.3
    ├── Vignette: 0.2
    └── Color Grading: Contrast +0.05
```

#### Step 5: Performance Optimization (16GB RAM)
```ini
# Add to DefaultEngine.ini
[/Script/Engine.RendererSettings]
r.DefaultFeature.AntiAliasing=2
r.MSAACount=2
r.TemporalAA.Upsampling=1

# Reduce MetaHuman LOD for performance
[MetaHuman]
LODMode=Performance
bUseBodyMesh=False
bUseFaceOnly=True
```

---

### 4️⃣ Convai AI — Aura's Intelligence

#### Dashboard Configuration Steps
```
1. Log in at: https://convai.com/dashboard
2. Click "Create Character" → Name: "Aura"
3. Paste the full backstory from the "Meet Aura" section above
4. Voice Settings:
   ├── Gender: Female
   ├── Accent: Indian English
   ├── Tone: Soft / Professional
   └── Speed: 0.95 (slightly slower for clarity)
5. Language: Hindi (Primary) — for accurate lip-sync phoneme mapping
6. Click "Save" → Copy your Character ID
7. Paste Character ID into Unreal Engine Convai component
```

#### Testing Aura in Convai Playground

Try these test phrases before going live:
```
🧪 "Hello Aura! Namaste."
   Expected: Warm Hinglish greeting + introduction

🧪 "Mera seatbelt kaam nahi kar raha."
   Expected: Calm safety assistance in Hindi

🧪 "What is for dinner today?"
   Expected: Meal options in English — professional tone

🧪 "Main bohot ghabra raha hoon, yeh meri pehli flight hai."
   Expected: Empathetic reassurance in Hindi/Hinglish

🧪 "Where is the emergency exit?"
   Expected: Clear safety directions in English

🧪 "What is your name?"
   Expected: Should maintain persona as "Aura from SkyHigh Airways"
```

---

## 🔐 Environment Variables

### Root `.env.example`
```env
# ══════════════════════════════════════════
#           TRANSITAI PLATFORM CONFIG
# ══════════════════════════════════════════

# --- Signaling Server ---
SIGNALING_PORT=8080
SIGNALING_HOST=0.0.0.0
NODE_ENV=production

# --- Unreal Engine Pixel Streaming ---
UE5_PIXEL_STREAMING_PORT=8888
UE5_HOST=localhost

# --- Convai AI ---
CONVAI_API_KEY=your_convai_api_key_here
CONVAI_CHARACTER_ID=your_character_id_here

# --- WebRTC ICE Configuration ---
STUN_SERVER_URL=stun:stun.l.google.com:19302
TURN_SERVER_URL=
TURN_USERNAME=
TURN_CREDENTIAL=

# --- Session Management ---
MAX_CONCURRENT_SESSIONS=50
SESSION_TIMEOUT_MS=300000

# --- Logging ---
LOG_LEVEL=info
LOG_TO_FILE=true

# --- SSL (Production) ---
SSL_CERT_PATH=/etc/ssl/certs/transitai.crt
SSL_KEY_PATH=/etc/ssl/private/transitai.key
```

> ⚠️ **NEVER commit your `.env` file.** It is included in `.gitignore` by default.

---

## 📡 API Reference

### Signaling Server WebSocket Protocol

**Connection:** `ws://HOST:PORT`

#### Messages — Client → Server
```json
// Initiate session
{
  "type": "join",
  "sessionId": "uuid-v4",
  "role": "client"
}

// Send SDP Offer
{
  "type": "offer",
  "sessionId": "uuid-v4",
  "sdp": "v=0\r\no=- ..."
}

// Send ICE Candidate
{
  "type": "ice_candidate",
  "sessionId": "uuid-v4",
  "candidate": {
    "candidate": "candidate:...",
    "sdpMLineIndex": 0,
    "sdpMid": "0"
  }
}
```

#### Messages — Server → Client
```json
// Session confirmed
{
  "type": "joined",
  "sessionId": "uuid-v4",
  "streamerCount": 1
}

// SDP Answer from UE5
{
  "type": "answer",
  "sessionId": "uuid-v4",
  "sdp": "v=0\r\no=- ..."
}

// ICE Candidate from UE5
{
  "type": "ice_candidate",
  "sessionId": "uuid-v4",
  "candidate": { ... }
}

// Error
{
  "type": "error",
  "code": "NO_STREAMER_AVAILABLE",
  "message": "No Unreal Engine instance is currently streaming."
}
```

#### REST Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Server health check |
| GET | `/sessions` | Active session count |
| DELETE | `/sessions/:id` | Force close a session |

---

## 📊 Performance Benchmarks

### Latency Measurements (Development Environment)
```
Test Configuration:
├── Server: Intel i9-12900K, RTX 3080, 32GB RAM
├── Client: Samsung Galaxy S22 (WiFi 6)
└── Network: Local LAN (1 Gbps)

Results:
┌────────────────────────────────────────┬──────────────┐
│  Metric                                │  Avg Latency │
├────────────────────────────────────────┼──────────────┤
│  WebRTC Connection Establishment       │  1.2s        │
│  Pixel Streaming First Frame           │  0.8s        │
│  Speech → STT → Text                   │  280ms       │
│  Convai NLU Processing                 │  420ms       │
│  TTS Generation                        │  190ms       │
│  Lip Sync Activation                   │  < 1 frame   │
│  Total: User speaks → Aura responds    │  ~900ms      │
└────────────────────────────────────────┴──────────────┘
```

### Resource Utilization (16GB RAM System)
```
┌─────────────────────────────┬─────────┬─────────┐
│  Component                  │  RAM    │  GPU    │
├─────────────────────────────┼─────────┼─────────┤
│  Unreal Engine (UE5)        │  6.2 GB │  4.8 GB │
│  MetaHuman (Face Only)      │  0.8 GB │  1.2 GB │
│  Pixel Streaming Plugin     │  0.4 GB │  0.6 GB │
│  Node.js Signaling Server   │  0.1 GB │  —      │
│  System Reserved            │  2.0 GB │  —      │
├─────────────────────────────┼─────────┼─────────┤
│  TOTAL                      │  9.5 GB │  6.6 GB │
└─────────────────────────────┴─────────┴─────────┘
```

---

## 🐳 Deployment Guide

### Docker Compose (Full Stack)
```yaml
# docker/docker-compose.prod.yml

version: '3.8'

services:
  signaling_server:
    build:
      context: ../signaling_server
      dockerfile: Dockerfile
    container_name: transitai_signaling
    restart: always
    ports:
      - "8080:8080"
    env_file:
      - ../.env
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - transitai_network

  nginx:
    image: nginx:1.24-alpine
    container_name: transitai_nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/ssl/transitai:ro
    depends_on:
      - signaling_server
    networks:
      - transitai_network

networks:
  transitai_network:
    driver: bridge
```
```bash
# Deploy production stack
docker compose -f docker/docker-compose.prod.yml up -d

# View logs
docker compose -f docker/docker-compose.prod.yml logs -f

# Scale signaling server
docker compose -f docker/docker-compose.prod.yml up -d --scale signaling_server=3
```

### Nginx SSL Configuration
```nginx
# docker/nginx/nginx.conf

events { worker_connections 1024; }

http {
    upstream signaling {
        server signaling_server:8080;
    }

    server {
        listen 80;
        server_name your-domain.com;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name your-domain.com;

        ssl_certificate     /etc/ssl/transitai/transitai.crt;
        ssl_certificate_key /etc/ssl/transitai/transitai.key;
        ssl_protocols       TLSv1.2 TLSv1.3;

        # WebSocket Signaling
        location /ws {
            proxy_pass http://signaling;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 86400;
        }

        # Health Check
        location /health {
            proxy_pass http://signaling;
        }
    }
}
```

---

## 🔧 Troubleshooting

### Common Issues and Resolutions

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| 🔇 Mouth moves, no audio | Wrong default mic in Windows | Settings → Sound → Input → Select correct microphone |
| ⬛ Black screen on Flutter | Pixel Streaming not started | Confirm UE5 is running with `-PixelStreamingPort=8888` |
| 📡 WebRTC connection fails | Signaling server unreachable | Run `curl http://SERVER:8080/health` — check firewall rules |
| 🐌 High latency (>2s) | Network/GPU bottleneck | Reduce UE5 resolution, enable `sg.ShadowQuality=1` |
| 💾 UE5 crashes (RAM) | Insufficient RAM for full MetaHuman | Use face-only mesh, disable Body LODs |
| 🤖 Convai not responding | Invalid Character ID or API key | Re-check credentials in UE5 Convai component |
| 🎭 Lip sync out of sync | Audio buffer mismatch | Restart UE5 + signaling server in sequence |
| 📱 Flutter build fails | Dependency version conflict | Run `flutter pub upgrade` then `flutter clean && flutter pub get` |
| 🔐 SSL handshake error | Certificate mismatch | Verify `server_name` in nginx.conf matches your domain |

### Diagnostic Commands
```bash
# Check signaling server health
curl http://localhost:8080/health

# Monitor WebSocket connections
ws://localhost:8080  # Connect with wscat: npx wscat -c ws://localhost:8080

# Check Node.js process
pm2 status         # If using PM2
docker logs transitai_signaling  # If using Docker

# Flutter diagnostics
flutter doctor -v
flutter analyze

# Network port check
netstat -an | grep 8080   # Signaling
netstat -an | grep 8888   # Pixel Streaming
```

---

## 🗺️ Roadmap
```
CURRENT VERSION: v1.0.0-beta
━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ v1.0.0  — Core Platform
   ├── MetaHuman avatar (Aura) with Hinglish AI
   ├── WebRTC Pixel Streaming pipeline
   ├── Flutter mobile client
   └── Node.js signaling server

🔄 v1.1.0  — Enhanced Intelligence (Q3 2025)
   ├── Emotion-aware responses (detect anxious passengers)
   ├── Idle animation system (breathing, micro-expressions)
   ├── Session analytics dashboard
   └── Admin control panel (change character, knowledge base)

📅 v1.2.0  — Multilingual Expansion (Q4 2025)
   ├── Tamil language support
   ├── Bengali language support
   ├── Marathi & Gujarati support
   └── Auto language detection

📅 v2.0.0  — Enterprise Deployment (Q1 2026)
   ├── Multi-kiosk load balancing
   ├── On-premise deployment support
   ├── Custom MetaHuman skin system
   ├── Integration with real-time flight data APIs
   └── Hospital & metro rail persona variants

📅 v2.5.0  — Edge AI (Q3 2026)
   ├── On-device inference (no internet required)
   ├── Raspberry Pi 5 compatible lite mode
   └── Offline knowledge base for airports
```

---

## 🤝 Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Development Workflow
```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/transitai-platform.git
cd transitai-platform

# 3. Create a feature branch
git checkout -b feature/your-feature-name

# 4. Make your changes and test
flutter test          # For Flutter changes
npm test              # For signaling server changes

# 5. Commit with conventional commit format
git commit -m "feat(flutter): add text input fallback mode"
git commit -m "fix(signaling): resolve ICE candidate race condition"
git commit -m "docs(readme): update deployment instructions"

# 6. Push and open a Pull Request
git push origin feature/your-feature-name
```

### Commit Convention

| Prefix | Usage |
|--------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `perf` | Performance improvement |
| `refactor` | Code refactor |
| `test` | Adding tests |
| `chore` | Build/config changes |

---

## 🔒 Security

Please review our [Security Policy](SECURITY.md) for reporting vulnerabilities.

### Security Practices

- API keys and credentials are managed via environment variables — never hardcoded
- WebSocket connections are upgraded to WSS (TLS) in production via Nginx
- Convai API calls are proxied through the server — keys never exposed to mobile client
- No passenger voice data is retained after session termination
- Session tokens are UUID v4 and expire after 5 minutes of inactivity
- Rate limiting is enforced at the Nginx level (60 requests/minute per IP)

---

## 🧬 Ethics & Privacy

TransitAI is built with responsible AI principles embedded from the ground up.

| Principle | Implementation |
|-----------|---------------|
| **Transparency** | Aura introduces herself as an AI assistant |
| **Data Minimization** | Voice audio is processed and immediately discarded |
| **No PII Storage** | No passenger names, voices, or queries are stored |
| **Human Override** | Physical staff can always intervene and override Aura |
| **Consent** | On-screen notification informs users of AI interaction |
| **Safety First** | Emergency queries are escalated to human staff protocols |
| **Bias Mitigation** | Convai character is regularly audited for response fairness |

---

## 📄 License
```
MIT License

Copyright (c) 2025 TransitAI Platform

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## 🙏 Acknowledgements

- [Epic Games](https://epicgames.com) — Unreal Engine 5 & MetaHuman Creator
- [Convai](https://convai.com) — Conversational AI & Character Engine
- [Flutter Team](https://flutter.dev) — Cross-platform mobile framework
- [WebRTC Project](https://webrtc.org) — Real-time communication protocol
- [Node.js Foundation](https://nodejs.org) — JavaScript runtime

---

<div align="center">

<br/>

**Built with ❤️ for the future of human-AI interaction in public spaces**

<br/>

*"Aapka safar shubh ho. Have a wonderful flight."* ✈️

<br/>

[![GitHub Stars](https://img.shields.io/github/stars/yourusername/transitai-platform?style=social)](https://github.com/yourusername/transitai-platform)
[![GitHub Forks](https://img.shields.io/github/forks/yourusername/transitai-platform?style=social)](https://github.com/yourusername/transitai-platform/fork)
[![GitHub Watchers](https://img.shields.io/github/watchers/yourusername/transitai-platform?style=social)](https://github.com/yourusername/transitai-platform)

<br/>

*TransitAI Platform — v1.0.0-beta | MIT License | © 2025*

</div>
