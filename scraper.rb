#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'
require 'wikidata_ids_decorator'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    members_table.xpath('.//tr[td[2]]').map { |tr| fragment(tr => MemberRow).to_h }
  end

  private

  def members_table
    noko.xpath('//table[.//th[contains(.,"Elected MP")]]')
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
