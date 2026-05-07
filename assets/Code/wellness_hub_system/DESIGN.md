---
name: Wellness Hub System
colors:
  surface: '#fbf9f9'
  surface-dim: '#dbdad9'
  surface-bright: '#fbf9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f3'
  surface-container: '#efeded'
  surface-container-high: '#e9e8e7'
  surface-container-highest: '#e3e2e2'
  on-surface: '#1b1c1c'
  on-surface-variant: '#44474e'
  inverse-surface: '#303031'
  inverse-on-surface: '#f2f0f0'
  outline: '#75777f'
  outline-variant: '#c5c6cf'
  surface-tint: '#4e5e81'
  primary: '#031635'
  on-primary: '#ffffff'
  primary-container: '#1a2b4b'
  on-primary-container: '#8293b8'
  inverse-primary: '#b6c6ef'
  secondary: '#735b22'
  on-secondary: '#ffffff'
  secondary-container: '#fddc96'
  on-secondary-container: '#775f26'
  tertiary: '#171714'
  on-tertiary: '#ffffff'
  tertiary-container: '#2c2b28'
  on-tertiary-container: '#94928e'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#b6c6ef'
  on-primary-fixed: '#081b3a'
  on-primary-fixed-variant: '#364768'
  secondary-fixed: '#ffdf9b'
  secondary-fixed-dim: '#e2c37f'
  on-secondary-fixed: '#251a00'
  on-secondary-fixed-variant: '#59440c'
  tertiary-fixed: '#e6e2dd'
  tertiary-fixed-dim: '#c9c6c1'
  on-tertiary-fixed: '#1c1c19'
  on-tertiary-fixed-variant: '#484743'
  background: '#fbf9f9'
  on-background: '#1b1c1c'
  surface-variant: '#e3e2e2'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  container-padding: 24px
  gutter: 16px
  section-gap: 32px
  stack-gap: 12px
---

## Brand & Style

This design system is built on a foundation of **Modern Minimalism** infused with a **Tactile** warmth. It is designed for individuals seeking a balanced, health-conscious lifestyle. The visual language aims to evoke a sense of calm reliability and premium accessibility. By combining high-contrast functional elements with a soft, organic color palette, the system provides a clear roadmap for personal growth without the aggressive aesthetic common in high-intensity fitness apps. 

The personality is encouraging, clear, and sophisticated, utilizing generous whitespace to reduce cognitive load and prioritize the user's daily focus.

## Colors

The palette is anchored by a deep, authoritative navy blue used for structural elements like headers and primary action triggers. This is balanced by a warm, golden tan that serves as a high-visibility accent for highlights, secondary progress indicators, and specialized buttons. 

The background uses a soft cream/off-white to provide a warmer, more organic feel than pure white, reducing eye strain. Functional states (success, warnings) should use muted versions of standard colors to maintain the "Wellness" aesthetic.

## Typography

The system utilizes **Plus Jakarta Sans** for its friendly yet modern geometric proportions. Headlines are bold and prominent to establish a clear information hierarchy. Body text uses sentence case to maintain a conversational and approachable tone. 

Spacing between typographic elements is generous, ensuring that even dense workout data remains legible and scannable at a glance.

## Layout & Spacing

This design system employs a **Fluid Grid** model with fixed safe-area margins. The layout philosophy prioritizes vertical flow for discovery and horizontal carousels for categorized content to maximize screen real estate on mobile devices.

A generous 24px container padding is standard across the system to maintain a spacious, premium feel. Elements within cards or specific sections should follow an 8px rhythmic scale to ensure consistent alignment and density.

## Elevation & Depth

Depth is communicated through **Ambient Shadows** and **Tonal Layers**. Surfaces do not rely on heavy borders; instead, they use very soft, diffused drop shadows (0px 4px 20px, 5-8% opacity) to lift cards from the cream background. 

Primary progress cards may use a solid fill of the secondary color (#DDBE7B) to create a "surface-container" effect that commands immediate attention without requiring extreme elevation.

## Shapes

The shape language is defined by extreme roundedness, creating a "soft-touch" feel. Standard cards and containers utilize a corner radius of 24px to 32px. Buttons and interactive toggles are strictly pill-shaped (fully rounded) to contrast with the more rectangular but soft-edged content cards. 

This high degree of roundedness reinforces the approachable and safe nature of the wellness environment.

## Components

### Buttons
- **Primary:** Pill-shaped, #1A2B4B background with white text.
- **Secondary:** Pill-shaped, #DDBE7B background with deep navy text.
- **Ghost:** Pill-shaped, 1px navy border with navy text.

### Cards
- **Discovery Cards:** White background, 24px radius, soft shadow, containing thin-stroke icons.
- **Featured Cards:** #DDBE7B background, 32px radius, used for "Current Progress" or "Active Plan."

### Navigation & Toggles
- **Pill Toggles:** A container with a pill-shaped "active" state that slides behind the text. Use #1A2B4B for the active background in the header area.
- **Tab Bar:** Clear, minimalist icons with a distinct "Active" state using the secondary color for the icon or a small indicator dot.

### Iconography
- **System Icons:** 1.5pt thin-stroke line icons for navigation and general actions.
- **Category Icons:** Minimalist solid icons placed within circular or rounded-square containers for quick visual recognition in lists.