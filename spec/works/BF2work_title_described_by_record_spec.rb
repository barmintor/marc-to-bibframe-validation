require 'spec_helper'
require 'linkeddata'

describe 'prefTitle of the work described by the MARC record' do

  # LD4All Sample MARC Test:
  # The prefTitle generated for the Work described by a MARC record.
  # Work altTitle, identifiers are tested elsewhere.
  # TBD: add 880 stuff.
  #
  # prefTitle logic: 1. Uniform title as main entry, no agent name (130) ;
  #                  2. Uniform title as main entry, with or without agent name (240) ;
  #                  3. Transcribed main title, with or without agent name (245) .
  #
  # Test logic: 1. If there is a 130 present:
  #                1a. The first (or only) subfield ($a or $k) == MainTitleElement instance (obl.: 1) of prefTitle of Work ;
  #                1b. The second (or other) subfield(s) == TitleElement instances (obl.: 0,n) of prefTitle of Work ;
  #                1c. The first indicator (when exists and != 0) == NonSortElement (obl.: 0,1) instance of prefTitle of Work ;
  #                1d. (to be improved) The first (or only) subfield ($a or $k) appears in the rdfs:label (obl: 1) of the prefTitle of the Work ;
  #                1e. 245 first (or only) subfield ($a or $k) is in the rdfs:label of prefTitle of Instance ;
  #                1f. Mapping of other 130 subfields to be added later to tests.
  #             2. Elif there is a 240 present (there should never be both a 130 and a 240):
  #                1a. The first (or only) subfield ($a or $k) == MainTitleElement instance (obl.: 1) of prefTitle of Work ;
  #                1b. The second (or other) subfield(s) == TitleElement instances (obl.: 0,n) of prefTitle of Work ;
  #                1c. The second indicator (when exists and != 0) == NonSortElement (obl.: 0,1) instance of prefTitle of Work ;
  #                1d. (to be improved) The first (or only) subfield ($a or $k) appears in the rdfs:label (obl: 1) of the prefTitle of the Work ;
  #                1e. 245 first (or only) subfield ($a or $k) is in the rdfs:label of prefTitle of Instance ;
  #                1f. Mapping of other 240 subfields to be added later to tests.
  #             3. Elif there is a 245 present (There should always be a 245):
  #                1a. The first (or only) subfield ($a or $k) == MainTitleElement of prefTitle of Work, Instance ;
  #                1b. The second (or other) subfield(s) == TitleElement instances of prefTitle of Work, Instance ;
  #                1c. The second indicator (when exists and != 0) == NonSortElement instance of prefTitle of Work ;
  #                1d. (to be improved) The first (or only) subfield ($a or $k) appears in the rdfs:label of the prefTitle of the Work ;
  #                1e. Mapping of other 245 subfields to be added later to tests (requires in depth logic for handling multiple titles in a 245).

  # Variable for Basic Single Monograph, Text, English LDR, 008 fields with 001 == BIB record identifier
  let(:marc_ldr_001_008) {
    '<record xmlns="http://www.loc.gov/MARC21/slim">
      <leader>01033cam a22002891  4500</leader>
      <controlfield tag="001">RECORD_ID</controlfield>
      <controlfield tag="008">860506s1957    nyua     b    000 0 eng  </controlfield>'
  }
  # SPARQL Query for MainTitleElement instance (obl.: 1) of prefTitle of Work ;
  let!(:mainElemTitle_of_work_sparql_query) {
    SPARQL.parse("PREFIX bf: <http://bibframe.org/vocab/>
                  PREFIX dcterms: <http://purl.org/dc/terms/>
                  PREFIX ld4l: <http://bib.ld4l.org/ontology/>
                  PREFIX madsrdf: <http://www.loc.gov/mads/rdf/v1#>
                  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                  SELECT DISTINCT ?mainElemValue
                  WHERE {
                    ?work a bf:Work ;
                      ld4l:hasPreferredTitle ?title .
                    ?title a madsrdf:Title ;
                      dcterms:hasPart ?mainElem .
                    ?mainElem a madsrdf:MainTitleElement ;
                      rdfs:label ?mainElemValue .
                  }") }
  # SPARQL Query for TitleElement instances (obl.: 0,n) of prefTitle of Work ;
  # This presumes all non-MainTitleElement classes are subclasses of madsrdf:TitleElement & inference is in place.
  let!(:otherElemTitle_of_work_sparql_query) {
    SPARQL.parse("PREFIX bf: <http://bibframe.org/vocab/>
                  PREFIX dcterms: <http://purl.org/dc/terms/>
                  PREFIX ld4l: <http://bib.ld4l.org/ontology/>
                  PREFIX madsrdf: <http://www.loc.gov/mads/rdf/v1#>
                  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                  SELECT DISTINCT ?otherElemValue
                  WHERE {
                    ?work a bf:Work ;
                      ld4l:hasPreferredTitle ?title .
                    ?title a madsrdf:Title ;
                      dcterms:hasPart ?mainElem .
                    ?mainElem a madsrdf:TitleElement ;
                      rdfs:label ?otherElemValue .
                  }") }
  # SPARQL Query for NonSortElement instance (obl.: 0,1) of prefTitle of Work ;
  let!(:nonSortValue_of_work_sparql_query) {
    SPARQL.parse("PREFIX bf: <http://bibframe.org/vocab/>
                  PREFIX dcterms: <http://purl.org/dc/terms/>
                  PREFIX ld4l: <http://bib.ld4l.org/ontology/>
                  PREFIX madsrdf: <http://www.loc.gov/mads/rdf/v1#>
                  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                  SELECT DISTINCT ?nonSortValue
                  WHERE {
                    ?work a bf:Work ;
                      ld4l:hasPreferredTitle ?title .
                    ?title a madsrdf:Title ;
                      dcterms:hasPart ?subtitle .
                    ?subtitleElem a madsrdf:NonSortElement ;
                      rdfs:label ?nonSortValue ;
                  }") }
  # SPARQL Query for rdfs:label (obl: 1) of the prefTitle of the Work ;
  let!(:titleValue_of_work_sparql_query) {
    SPARQL.parse("PREFIX bf: <http://bibframe.org/vocab/>
                  PREFIX ld4l: <http://bib.ld4l.org/ontology/>
                  PREFIX madsrdf: <http://www.loc.gov/mads/rdf/v1#>
                  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                  SELECT DISTINCT ?titleValue
                  WHERE {
                    ?work a bf:Work ;
                      ld4l:hasPreferredTitle ?title .
                    ?title a madsrdf:Title ;
                      rdfs:label ?titleValue .
                  }") }
  # SPARQL Query for MainTitleElement (obl.: 1) of prefTitle of Instance ;
  let!(:mainElemValue_of_work_sparql_query) {
    SPARQL.parse("PREFIX bf: <http://bibframe.org/vocab/>
                  PREFIX dcterms: <http://purl.org/dc/terms/>
                  PREFIX ld4l: <http://bib.ld4l.org/ontology/>
                  PREFIX madsrdf: <http://www.loc.gov/mads/rdf/v1#>
                  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                  SELECT DISTINCT ?instTitleValue
                  WHERE {
                    ?in a bf:Instance ;
                      ld4l:hasPreferredTitle ?title .
                    ?title a madsrdf:Title ;
                      rdfs:label ?instTitleValue .
                  }") }

  let(:graph) { self.send(MARC2BF_GRAPH_METHOD, marcxml_str, rec_id) }

  context "130" do
    # 1. If there is a 130 present:
    context "‡a (+ 245) only" do
      # 1a. The *only* subfield ($a or $k) == MainTitleElement instance (obl.: 1) of prefTitle of Work ;
      let!(:rec_id) { '130a_only' }
      let(:marcxml_str) do
        marc_ldr_001_008.sub('RECORD_ID', rec_id) +
          '<datafield ind1="0" ind2=" " tag="130">
            <subfield code="a">Beowulf.</subfield>
          </datafield>
          <datafield ind1="1" ind2="0" tag="245">
            <subfield code="a">IGNORE</subfield>
            <subfield code="c">IGNORE</subfield>
          </datafield>
        </record>'
      end

      context "queried for works" do
        subject { graph.query(WorkHelpers::WORK_SPARQL_QUERY) }
        it 'return a single work' do
          is_expected.to have(1).items
        end
      end
      context "queried for titles" do
        subject { graph.query(mainElemTitle_of_work_sparql_query) }
        let(:title_value) { subject.first.mainElemValue.to_s }
        it 'work title from 130' do
          is_expected.to have(1).items
        end
        it 'work title from 130' do
          expect(title_value).to match(/Beowulf/)
          expect(title_value).not_to match(/IGNORE/)
        end
      end
    end

    context "‡a, ‡l, ‡s, ‡f, ‡= (+ 245) only" do
      # 1a. The *first* subfield ($a or $k) == MainTitleElement instance (obl.: 1) of prefTitle of Work ;
      let!(:rec_id) { '130a_first' }
      let!(:marcxml_str) do
        marc_ldr_001_008.sub('RECORD_ID', rec_id) +
          '<datafield ind1="0" ind2=" " tag="130">
            <subfield code="a">Beowulf</subfield>
            <subfield code="l">IGNORE</subfield>
            <subfield code="s">IGNORE</subfield>
            <subfield code="f">IGNORE</subfield>
            <subfield code="=">IGNORE</subfield>
           </datafield>
           <datafield ind1="0" ind2="0" tag="245">
            <subfield code="a">IGNORE</subfield>
            <subfield code="b">IGNORE</subfield>
            <subfield code="c">IGNORE</subfield>
           </datafield>
        </record>'
      end

      context "queried for works" do
        subject { graph.query(WorkHelpers::WORK_SPARQL_QUERY) }
        it 'return a single work' do
          is_expected.to have(1).items
        end
      end
      context "queried for titles" do
        subject { graph.query(mainElemTitle_of_work_sparql_query) }
        let(:title_value) { subject.first.mainElemValue.to_s }
        it do
          is_expected.to have(1).items
        end
        it 'gets work title from 130' do
          expect(title_value).to match(/Beowulf/)
          expect(title_value).not_to match(/IGNORE/)
        end
      end
    end

    context "‡l, ‡s, ‡f, ‡= (+ 245) only" do
      # 1b. The second (or other) subfield(s) == TitleElement instances (obl.: 0,n) of prefTitle of Work ;
      let!(:rec_id) { '130_lsfeq' }
      let!(:marcxml_str) do
        marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="0" ind2=" " tag="130">
          <subfield code="a">Beowulf</subfield>
          <subfield code="l">Danish &amp; Anglo-Saxon.</subfield>
          <subfield code="s">Schaldemose.</subfield>
          <subfield code="f">1847.</subfield>
          <subfield code="=">^A944917</subfield>
         </datafield>
         <datafield ind1="0" ind2="0" tag="245">
          <subfield code="a">IGNORE</subfield>
          <subfield code="b">IGNORE</subfield>
          <subfield code="c">IGNORE</subfield>
         </datafield>
      </record>'
      end

      context "queried for works" do
        subject { graph.query(WorkHelpers::WORK_SPARQL_QUERY) }
        it 'return a single work' do
          is_expected.to have(1).items
        end
      end
      context "queried for titles" do
        subject { graph.query(otherElemTitle_of_work_sparql_query) }
        let(:title_value) { subject.first.otherElemValue.to_s }
        it do
          is_expected.to have(5).items
        end
        it 'gets work title from 130' do
          expect(title_value).to match(/Danish|Schaldemose|1847|944917/)
          expect(title_value).not_to match(/IGNORE|Beowulf/)
        end
      end
    end

    context 'has non-filing chars' do
      # 1c. The first indicator (when exists and != 0) == NonSortElement (obl.: 0,1) instance of prefTitle of Work ;
      let!(:rec_id) { '130_ind1' }
      let!(:marcxml_str) do
        marc_ldr_001_008.sub('RECORD_ID', rec_id) +
        '<datafield ind1="1" ind2=" " tag="130">
           <subfield code="a">Lid un tfile.</subfield>
         </datafield>
         <datafield ind1="1" ind2="0" tag="245">
           <subfield code="6">IGNORE</subfield>
           <subfield code="a">IGNORE</subfield>
           <subfield code="c">IGNORE</subfield>
         </datafield>
      </record>'
      end

      context "queried for titles" do
        subject { graph.query(nonSortValue_of_work_sparql_query) }
        let(:title_value) { subject.first.nonSortValue.to_s }
        it do
          is_expected.to have(1).items
        end
        it 'gets work title from 130' do
          expect(title_value).to match(/^L$/)
          expect(title_value).not_to match(/IGNORE|un tfile/)
        end
      end
    end

    #   1d. (to be improved) The first (or only) subfield ($a or $k) appears in the rdfs:label (obl: 1) of the prefTitle of the Work ;
    #   1e. 245 first (or only) subfield ($a or $k) is in the rdfs:label of prefTitle of Instance ;
    #   1f. Mapping of other 130 subfields to be added later to tests.
  end # context 130

  context "240 only" do
  # 2. If there is a 240 present (there should never be both a 130 and a 240):
    # 1a. The first (or only) subfield ($a or $k) == MainTitleElement instance (obl.: 1) of prefTitle of Work ;
    # 1b. The second (or other) subfield(s) == TitleElement instances (obl.: 0,n) of prefTitle of Work ;
    # 1c. The second indicator (when exists and != 0) == NonSortElement (obl.: 0,1) instance of prefTitle of Work ;
    # 1d. (to be improved) The first (or only) subfield ($a or $k) appears in the rdfs:label (obl: 1) of the prefTitle of the Work ;
    # 1e. 245 first (or only) subfield ($a or $k) is in the rdfs:label of prefTitle of Instance ;
    # 1f. Mapping of other 240 subfields to be added later to tests.
  end # only 240
end
