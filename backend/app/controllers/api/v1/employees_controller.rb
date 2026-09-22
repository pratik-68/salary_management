module Api
  module V1
    class EmployeesController < ApplicationController
      include Pagy::Backend

      # A ceiling rather than an error: asking for 5,000 rows gets the largest
      # page we will serve, and the meta says what was actually returned.
      MAX_PER_PAGE = 100

      # GET /api/v1/employees
      #
      # Always paginated. The browser never receives 10,000 rows, which is what
      # keeps this fast without any caching to keep in step with edits.
      def index
        filter = EmployeeFilter.new(params)
        pagination, employees = pagy(filter.sorted_scope, page: page_number, limit: per_page)

        render json: {
          data: EmployeeSerializer.many(employees),
          meta: { page: pagination.page, per_page: pagination.limit, total: pagination.count }
        }
      end

      # GET /api/v1/employees/:id
      def show
        render json: { data: EmployeeSerializer.one(employee) }
      end

      # POST /api/v1/employees
      def create
        new_employee = Employee.new(employee_params)

        if new_employee.save
          render json: { data: EmployeeSerializer.one(new_employee) }, status: :created
        else
          render_invalid(new_employee)
        end
      end

      # PATCH /api/v1/employees/:id
      def update
        if employee.update(employee_params)
          render json: { data: EmployeeSerializer.one(employee) }
        else
          render_invalid(employee)
        end
      end

      private

      def employee
        @employee ||= Employee.find(params[:id])
      end

      # Currency is deliberately absent: it is derived from the country, so
      # accepting it would let the two disagree.
      def employee_params
        params.expect(
          employee: %i[
            employee_code first_name last_name email country_code
            department job_title level annual_salary hire_date
          ]
        )
      end

      def page_number
        positive_integer(params[:page], name: "page") || 1
      end

      def per_page
        requested = positive_integer(params[:per_page], name: "per_page")
        return Pagy::DEFAULT[:limit] if requested.nil?

        [ requested, MAX_PER_PAGE ].min
      end

      # A blank param means "use the default"; anything else has to be a whole
      # number above zero, so page=0 or page=two is a clear 400 rather than a
      # silently different page of results.
      def positive_integer(value, name:)
        return nil if value.blank?

        integer = Integer(value.to_s, exception: false)
        return integer if integer&.positive?

        raise InvalidParams.new("#{name} must be a whole number greater than zero.", code: "invalid_#{name}")
      end
    end
  end
end
