/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './app/views/**/*.{html,erb,rb}',
    './app/helpers/**/*.rb',
    './app/components/**/*.rb',
    './app/javascript/**/*.js',
    './lib/monitorix/app/views/**/*.rb',
    './lib/monitorix/app/components/**/*.rb'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
