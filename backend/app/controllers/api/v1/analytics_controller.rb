module Api
  module V1
    class AnalyticsController < ApplicationController
      # GET /api/v1/analytics/breakdown
      #
      # Both insight views come from here: group_by=country for what each
      # country costs, or a country filter plus any other grouping for how pay
      # varies inside it. Computed on read, so a figure is never stale.
      def breakdown
        render json: BreakdownSerializer.one(Analytics::Breakdown.new(params))
      end
    end
  end
end
