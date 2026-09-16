const KIT = [
  { src: "/pixels/palette.png", name: "palette", note: "16 locked colors" },
  { src: "/pixels/intro-house.png", name: "intro-house", note: "Night cottage, no ivy" },
  { src: "/pixels/intro-ivy-1.png", name: "intro-ivy-1", note: "Vine overlay stage 1" },
  { src: "/pixels/intro-ivy-2.png", name: "intro-ivy-2", note: "Vine overlay stage 2" },
  { src: "/pixels/intro-ivy-3.png", name: "intro-ivy-3", note: "Vine overlay stage 3" },
  { src: "/pixels/intro-ivy-4.png", name: "intro-ivy-4", note: "Vine overlay stage 4" },
  { src: "/pixels/intro-covered.png", name: "intro-covered", note: "House + full ivy" },
  { src: "/pixels/room.png", name: "room", note: "Interior with hotspots placed" },
  { src: "/pixels/obj-bed.png", name: "obj-bed", note: "Bed hotspot" },
  { src: "/pixels/obj-table.png", name: "obj-table", note: "Table under the ticket" },
  { src: "/pixels/obj-ticket.png", name: "obj-ticket", note: "8.17 ticket hotspot" },
  { src: "/pixels/obj-plaque.png", name: "obj-plaque", note: "9.29 wall plaque" },
  { src: "/pixels/ui-dialogue.png", name: "ui-dialogue", note: "RPG text box" },
  { src: "/pixels/ui-skip.png", name: "ui-skip", note: "Intro skip" },
  { src: "/pixels/ui-hand.png", name: "ui-hand", note: "Tap prompt" },
  { src: "/pixels/frame-photo.png", name: "frame-photo", note: "Frame for real photos" },
] as const;

/**
 * Temporary kit board so the pixel set can be reviewed at native scale.
 */
export default function App() {
  return (
    <main className="kit">
      <header className="kit__head">
        <h1>Ivy pixel kit</h1>
        <p>160×240 canvas · 16-bit palette · regenerate with npm run pixels</p>
      </header>
      <ul className="kit__grid">
        {KIT.map((item) => (
          <li key={item.name} className="kit__card">
            <div className="kit__stage">
              <img src={item.src} alt={item.name} />
            </div>
            <strong>{item.name}</strong>
            <span>{item.note}</span>
          </li>
        ))}
      </ul>
    </main>
  );
}
