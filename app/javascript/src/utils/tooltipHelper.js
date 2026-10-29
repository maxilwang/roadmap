import { Tooltip } from 'bootstrap';

const initializeTooltips = () => {
  document
    .querySelectorAll(
      '[data-bs-toggle="tooltip"], [data-toggle="tooltip"]'
    )
    .forEach((element) => {
      // Avoid initializing the same tooltip more than once.
      if (Tooltip.getInstance(element)) {
        return;
      }

      const placement =
        element.getAttribute('data-bs-placement') ||
        element.getAttribute('data-placement') ||
        'right';

      const html =
        element.getAttribute('data-bs-html') === 'true' ||
        element.getAttribute('data-html') === 'true';

      Tooltip.getOrCreateInstance(element, {
        placement,
        html,
        animation: true,
      });
    });
};

document.addEventListener('DOMContentLoaded', initializeTooltips);
document.addEventListener('turbo:load', initializeTooltips);
