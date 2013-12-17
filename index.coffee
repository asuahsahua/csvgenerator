#!/usr/bin/env coffee
_ = require 'underscore'
_.mixin require('underscore.string').exports()
Faker = require 'Faker'
csv = require 'csv'

class Record
  fields: null
  constructor: (@fields={}) ->
  toArray: (mapping) ->
    @fields[key] || null for key of mapping
  set: (mapping) ->
    @fields[key] = value for key, value of mapping
  get: (key) ->
    @fields[key]

class CsvGenerator
  @defaultMapping:
    email: "Email Address"
    first: "First Name"
    last: "Last Name"
    salutation: "Salutation"
    addressOne: "Address One"
    addressTwo: "Address Two"
    city: "City"
    zip: "Zip Code"
    company: "Company"
    website: "Website"
    phone: "Phone Number"
    fax: "Fax Number"
    years: "Years In Business"
    title: "Job Title"
    industry: "Industry"
    department: "Department"
    source: "Source"
    employees: "Number of Employees"
    doNotEmail: "Do Not Email"
    doNotCall: "Do Not Call"
    comments: "Comments"
    annualRevenue: "Annual Revenue"
    state: "State"
    territory: "Territory"
    country: "Country"

  @emailify: (first, last, company) ->
    "#{first}.#{last}@#{_.slugify company}.com".toLowerCase()

  @websiteify: (company) ->
    "http://www.#{_.slugify company}.com".toLowerCase()

  @getRandom: (mapping) ->
    # https://github.com/marak/Faker.js/
    first = Faker.Name.firstName()
    last = Faker.Name.lastName()
    company = Faker.Company.companyName()

    record = new Record
      email: @emailify first, last, company
      first: first
      last: last
      salutation: Faker.random.name_prefix()
      addressOne: Faker.Address.streetAddress()
      addressTwo: Faker.Address.secondaryAddress()
      city: Faker.Address.city()
      zip: Faker.Address.zipCode()
      company: company
      website: @websiteify company
      phone: Faker.PhoneNumber.phoneNumber()
      fax: Faker.PhoneNumber.phoneNumber()
      years: _.random(1, 25)
      title: Faker.Company.bs()
      industry: Faker.Company.bs()
      department: Faker.Company.bs()
      source: Faker.Internet.domainName()
      employees: _.random(1, 300)
      doNotEmail: [true, false][_.random(0, 1)]
      doNotCall: [true, false][_.random(0, 1)]
      comments: Faker.Lorem.sentence()
      annualRevenue: _.random(100, 100000000)
    if _.random(0, 1) is 1
      record.set
        state: Faker.Address.usState()
        country: "United States"
    else
      record.set
        territory: Faker.Address.ukCounty()
        country: "United Kingdom"

    return record.toArray mapping

  @poolSize: 1000

  @generate: (toGenerate=10, mapping=@defaultMapping) ->
    ## Output the header line
    csv().from([v for k,v of mapping]).to((d) -> console.log d)

    ## Output the rest - with grouping because it looks like csv() 
    ## queues in the background, causing OOM issues.
    workQueued = 0
    work = =>
      csv().from([@getRandom mapping]).to (d) ->
        console.log d
        if workQueued < toGenerate
          workQueued++
          work()
    for i in [0..._.min([toGenerate, 5000])]
      workQueued++
      work()
CsvGenerator.generate(2 * 1000 * 1000)
#CsvGenerator.generate(1000)
