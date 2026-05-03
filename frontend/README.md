# Truckr® Landing Page - Frontend

React + Deno + TypeScript frontend for the Truckr® landing page.

## Setup

### Prerequisites

- Deno 2.0+

### Installation

```bash
# Install dependencies (using Deno)
deno cache --reload deno.json
```

## Development

```bash
# Start development server on http://localhost:5173
deno task dev
```

## Build

```bash
# Build for production
deno task build
```

## Preview

```bash
# Preview production build
deno task preview
```

## Project Structure

```plain
frontend/
├── src/
│   ├── App.tsx         # Main landing page component
│   ├── main.tsx        # React entry point
├── index.html          # HTML entry point
├── vite.config.ts      # Vite configuration
├── tsconfig.json       # TypeScript configuration
└── deno.json           # Deno configuration
```

## Color Palette

- **Primary (Frosted Mint)**: `#bee4fa`
- **Secondary (Radiant Dandelion)**: `#f1e3aa`
- **Tertiary (Light Gray)**: `#b4b4b4`
- **Error (Coral)**: `#ff9999`
- **Neutral (White)**: `#ffffff`

## Features

- Responsive design
- Server-side data integration with Rails API
- Interactive hover effects
- Stats showcase
- Feature highlights for both transportistas and clientes
