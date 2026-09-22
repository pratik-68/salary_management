module Api
  module V1
    class MetaController < ApplicationController
      # GET /api/v1/meta
      #
      # The reference-data catalog that drives the filter bar and the employee
      # form. It only changes when the code does, so the SPA fetches it once.
      def show
        render json: { data: ReferenceDataSerializer.one }
      end
    end
  end
end
