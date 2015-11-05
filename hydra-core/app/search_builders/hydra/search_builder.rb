module Hydra
  class SearchBuilder < Blacklight::Solr::SearchBuilder
    self.default_processor_chain += [:add_access_controls_to_solr_params]
    include Hydra::AccessControlsEnforcement
  end
end
