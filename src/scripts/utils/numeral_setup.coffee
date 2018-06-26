# numeral = require 'numeral'
#
# numeral.register 'locale', 'en-IE',
#   delimiters:
#     thousands: ' ',
#     decimal: ','
#   abbreviations:
#     thousand: 'k',
#     million: 'm',
#     billion: 'b',
#     trillion: 't'
#   ordinal: (number) ->
#     return number is 1 ? 'st' : 'nd'
#   currency:
#     symbol: '€'
#
# # numeral.register 'locale', 'en-GB', require 'numeral/locales/en-gb'
#
# numeral.register 'locale', 'en-CA',
#   delimiters:
#     thousands: ' ',
#     decimal: ','
#   abbreviations:
#     thousand: 'k',
#     million: 'm',
#     billion: 'b',
#     trillion: 't'
#   ordinal: (number) ->
#     return number is 1 ? 'st' : 'nd'
#   currency:
#     symbol: '$'
#
# numeral.register 'locale', 'en-KW',
#   delimiters:
#     thousands: ' ',
#     decimal: ','
#   abbreviations:
#     thousand: 'k',
#     million: 'm',
#     billion: 'b',
#     trillion: 't'
#   ordinal: (number) ->
#     return number is 1 ? 'st' : 'nd'
#   currency:
#     symbol: 'KD'
#
# numeral.register 'locale', 'en-SG',
#   delimiters:
#     thousands: ' ',
#     decimal: ','
#   abbreviations:
#     thousand: 'k',
#     million: 'm',
#     billion: 'b',
#     trillion: 't'
#   ordinal: (number) ->
#     return number is 1 ? 'st' : 'nd'
#   currency:
#     symbol: '$'
#
# numeral.register 'locale', 'en-NZ',
#   delimiters:
#     thousands: ' ',
#     decimal: ','
#   abbreviations:
#     thousand: 'k',
#     million: 'm',
#     billion: 'b',
#     trillion: 't'
#   ordinal: (number) ->
#     return number is 1 ? 'st' : 'nd'
#   currency:
#     symbol: '$'
#
# numeral.register 'locale', 'en-AU',
#   delimiters:
#     thousands: ' ',
#     decimal: ','
#   abbreviations:
#     thousand: 'k',
#     million: 'm',
#     billion: 'b',
#     trillion: 't'
#   ordinal: (number) ->
#     return number is 1 ? 'st' : 'nd'
#   currency:
#     symbol: '$'
#
# numeral.register 'locale', 'nl', require 'numeral/locales/nl-nl'
# numeral.register 'locale', 'nl-BE', require 'numeral/locales/nl-nl'
# numeral.register 'locale', 'fr-BE', require 'numeral/locales/fr'
#
# numeral.register 'locale', 'en-NL',
#   delimiters:
#     thousands: ' ',
#     decimal: ','
#   abbreviations:
#     thousand: 'k',
#     million: 'm',
#     billion: 'b',
#     trillion: 't'
#   ordinal: (number) ->
#     return number is 1 ? 'st' : 'nd'
#   currency:
#     symbol: '€'
#
# numeral.register 'locale', 'en-MT',
#   delimiters:
#     thousands: ' ',
#     decimal: ','
#   abbreviations:
#     thousand: 'k',
#     million: 'm',
#     billion: 'b',
#     trillion: 't'
#   ordinal: (number) ->
#     return number is 1 ? 'st' : 'nd'
#   currency:
#     symbol: '€'
#
# languageFromLocale = (locale) ->
#   numeral.register 'locale',(locale)
#
# module.exports =
#   languageFromLocale: languageFromLocale
#   language: numeral.locales
