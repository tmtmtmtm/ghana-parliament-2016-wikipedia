#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'
require 'wikidata_ids_decorator'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    members_table.xpath('.//tr[td[2]]').map do |tr|
      data = fragment(tr => MemberRow).to_h
      data.merge(party: party_lookup.fetch(data[:partyLabel])[:id])
    end
  end

  field :parties do
    party_table.xpath('.//tr[.//a]').map { |tr| fragment(tr => PartyRow).to_h }
  end

  private

  def members_table
    noko.xpath('//table[.//th[contains(.,"Elected MP")]]')
  end

  def party_table
    noko.xpath('//table[.//td[contains(.,"Affiliation")]]').first
  end

  def party_lookup
    @party_lookup ||= parties.map { |party| [party[:shortname], party] }.to_h
  end
end

class PartyRow < Scraped::HTML
  field :id do
    tds[0].css('a/@wikidata').map(&:text).first
  end

  field :shortname do
    name_parts.captures.last
  end

  field :name do
    name_parts.captures.first
  end

  private

  def tds
    noko.css('td')
  end

  def name_parts
    @name_parts ||= tds[0].css('a').map(&:text).map(&:tidy).first.match(/(.*?) \((\w+)\)/)
  end
end

class MemberRow < Scraped::HTML
  field :id do
    tds[1].css('a/@wikidata').map(&:text).first
  end

  field :name do
    tds[1].css('a').map(&:text).map(&:tidy).first || tds[1].text
  end

  field :constituencyLabel do
    tds[0].css('a').map(&:text).map(&:tidy).first || tds[0].text
  end

  field :constituency do
    tds[0].css('a/@wikidata').map(&:text).first
  end

  field :partyLabel do
    tds[2].text.tidy
  end

  field :party do
    # Lookup table
    # tds[2].css('a/@wikidata').map(&:text).first
  end

  private

  def tds
    noko.css('td')
  end
end

url = 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_2016_Ghanaian_parliamentary_election'
data = Scraped::Scraper.new(url => MembersPage).scraper.members

header = data.first.keys.to_csv
rows = data.map { |row| row.values.to_csv }
puts header + rows.join
