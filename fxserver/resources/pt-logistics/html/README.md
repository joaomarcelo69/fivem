# pt-logistics NUI

This folder contains the HTML, CSS, and JS for the logistics management panel in the FiveM Portuguese RP server.

## Files
- `index.html`: Main markup for the logistics panel, showing warehouse stock, active routes, and close button.
- `style.css`: Styles for the panel, warehouse, routes, and actions.
- `app.js`: Handles NUI messages, updates panel with warehouse/routes, and close button logic.

## Usage
- The panel is shown via NUI message `showLogisticsPanel` with payload `{ warehouse, routes }`.
- Closing the panel sends a POST to `https://pt-logistics/closePanel`.
- Integrate with client.lua to open/close and update the panel from server-side logistics events.
