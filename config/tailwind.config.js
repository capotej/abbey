const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  darkMode: 'class',
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  safelist: [
    'bg-red-200', 'bg-green-200', 'bg-blue-200', 'bg-yellow-200', 'bg-purple-200',
    'dark:bg-red-700', 'dark:bg-green-700', 'dark:bg-blue-700', 'dark:bg-yellow-700', 'dark:bg-purple-700',
    'text-red-700', 'text-green-700', 'text-blue-700', 'text-yellow-700', 'text-purple-700',
    'dark:text-red-300', 'dark:text-green-300', 'dark:text-blue-300', 'dark:text-yellow-300', 'dark:text-purple-300'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    // require('@tailwindcss/typography'),
    // require('@tailwindcss/container-queries'),
  ]
}
