#!/usr/bin/env coffee

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

class CensusReader
  @read: (filename) ->
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

    return new ChanceGroup _(names).filter (obj) -> not _.isUndefined obj

class FlatDistReader
  @read: (filename) ->
    data = fs.readFileSync filename, 'utf8'
    return console.log "There was a problem reading #{filename}" if not data

    lines = _.lines data
    
    cumulative = 0
    names = lines.map (line) ->
      return undefined if not line
      return {
        data: _.capitalize line
        chance: 1
        cumulative: cumulative++
      }
    return new ChanceGroup _(names).filter (obj) -> not _.isUndefined obj

class CsvLine
  constructor: (@details) ->

  toString: (mapping) ->
    return _.join ",", _(@details).map (value, key) -> value

class CsvGenerator
  @firstNames: CensusReader.read 'census-derived-all-first.txt'
  @lastNames: CensusReader.read 'census-dist-2500-last.txt'
  @companies: FlatDistReader.read 'fortune500.txt'

  @getRandom: ->
    first = @firstNames.getRandom()
    last = @lastNames.getRandom()
    company = @companies.getRandom()

    return new CsvLine
      firstName: first
      lastName: last
      company: company
      email: "#{first}.#{last}@#{_.slugify company}.com".toLowerCase()
      website: "http://www.#{_.slugify company}.com".toLowerCase()

  @generate: (count=10) ->
    mapping =
      firstName: "First Name"
      lastName: "Last Name"
      company: "Company"
      email: "Email"
      website: "Website"

    output = []
    header = _.join ",", _(mapping).map (value) -> value
    console.log header

    for i in [0...count]
      console.log @getRandom().toString mapping + "\n"

CsvGenerator.generate(2)

## Default Fields to have:
# Zip
# Years in business
# territory
# state
# source
# salutation
# phone
# job title
# industry
# fax
# employees
# do not email
# do not call
# department
# country
# comments
# city
# annual revenue
# address two
# address one
