# ColorPick

Miniapp macOS per la menu bar: prelevi un colore dallo schermo e il codice HEX va negli appunti.

## Funzioni

- **Pick Color**: apre la lente di sistema; clicchi un punto qualsiasi dello schermo e il colore viene copiato come `#RRGGBB` (sRGB).
- **Storico**: gli ultimi 20 colori sono nel menu, ciascuno con un'anteprima. Se ne clicchi uno lo copi negli appunti. I primi 9 hanno i tasti rapidi 1–9.
- **Clear History** svuota lo storico.

Lo storico resta salvato tra un avvio e l'altro.

## Requisiti

- macOS 14 o successivo
- Xcode o Command Line Tools (Swift 6)

## Build

```bash
./build.sh
open ColorPick.app
```

Per avviarla in automatico al login, copia `ColorPick.app` in `/Applications` e aggiungila in Impostazioni di Sistema → Generali → Elementi login.

## Crediti

Ispirata all'estensione [Color Picker](https://www.raycast.com/thomas/color-picker) per Raycast (licenza MIT).
