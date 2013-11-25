fs = require 'fs'
_ = require 'underscore'
_.mixin require('underscore.string').exports()

class ChanceGroup
  constructor: (@units) ->
    chances = @units.map (a) -> a.chance
    @cumulative = _.reduce chances, ((a, b) -> a + b), 0

  getRandom: ->
    result = _.random 0, @cumulative
    units = _.filter @units, (unit) -> unit.cumulative < result
    return _.max(units, (unit) -> unit.cumulative).data

readCensus = (filename) ->
  data = fs.readFileSync filename, 'utf8'
  console.log "There was a problem reading first names" if not data

  lines = _.lines data

  cumulative = 0
  names = lines.map (line) ->
    return undefined if not line
    words = _.words line
    cumulative += parseInt words[3] * 1000, 10
    return {
      data: _.capitalize words[0].toLowerCase()
      chance: parseInt words[1] * 1000, 10
      cumulative: cumulative
    }

  return _(names).filter (obj) -> not _.isUndefined obj

readCompanies = (filename) ->
  data = fs.readFileSync filename, 'utf8'
  return console.log "There was a problem reading companies" if not data

  lines = _.lines data
  
  cumulative = 0
  names = lines.map (line) ->
    return undefined if not line
    return {
      data: _.capitalize line
      chance: 1
      cumulative: cumulative++
    }
  return _(names).filter (obj) -> not _.isUndefined obj

class CsvLine
  constructor: (@details) ->

  toString: (mapping) ->
    return _.join ",", _(@details).map (value, key) -> value

class CsvGenerator
  firstNames: new ChanceGroup readCensus 'census-derived-all-first.txt'
  lastNames: new ChanceGroup readCensus 'census-dist-2500-last.txt'
  companies: new ChanceGroup readCompanies 'fortune500.txt'

  constructor: ->

  getRandom: ->
    first = @firstNames.getRandom()
    last = @lastNames.getRandom()
    company = @companies.getRandom()

    return new CsvLine
      firstName: first
      lastName: last
      company: company
      email: "#{first}.#{last}@#{_.slugify company}.com".toLowerCase()

  generate: (count=10) ->
    # Todo mapping
    mapping =
      firstName: "First Name"
      lastName: "Last Name"
      company: "Company"
      email: "Email"

    output = []
    output.push _.join ",", _(mapping).map (value) -> value

    for i in [0..count]
      console.log @getRandom().toString mapping + "\n"

generator = new CsvGenerator()
console.log generator.generate(10000000)
