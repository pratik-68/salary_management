// Creating and editing an employee.
//
// A drawer rather than a page of its own: the list stays behind it, so the
// HR Manager keeps their place in the results they were working through.
//
// The form only offers what the catalog allows and the API validates the same
// rules again. Anything the API still rejects comes back per field, which is
// why validation messages land under the input that caused them.

import { App, Button, DatePicker, Drawer, Flex, Form, Input, InputNumber, Select } from 'antd'
import type { FormInstance } from 'antd'
import dayjs from 'dayjs'
import type { Dayjs } from 'dayjs'
import { ApiError } from '../../api/client'
import { useCreateEmployee, useUpdateEmployee } from '../../api/employees'
import { useReferenceData } from '../../api/meta'
import type { Employee, EmployeeInput } from '../../api/types'

interface FormValues {
  employee_code: string
  first_name: string
  last_name: string
  email: string
  country_code: string
  department: string
  job_title: string
  level: string
  annual_salary: number
  hire_date: Dayjs
}

interface Props {
  open: boolean
  /** The employee being edited, or undefined when adding a new one. */
  employee?: Employee
  onClose: () => void
}

export default function EmployeeFormDrawer({ open, employee, onClose }: Props) {
  const [form] = Form.useForm<FormValues>()
  const { message } = App.useApp()
  const { data: catalog } = useReferenceData()
  const create = useCreateEmployee()
  const update = useUpdateEmployee()

  const isEditing = employee !== undefined
  const saving = create.isPending || update.isPending

  const countryCode = Form.useWatch('country_code', form)
  const department = Form.useWatch('department', form)

  // The salary field is labelled with the currency of the country chosen
  // above it, so it is never ambiguous what the number means.
  const currency = catalog?.countries.find((country) => country.code === countryCode)?.currency
  const jobTitles =
    catalog?.departments.find((candidate) => candidate.name === department)?.job_titles ?? []

  const handleFinish = (values: FormValues) => {
    const input: EmployeeInput = {
      ...values,
      // The API stores a calendar day, not a moment.
      hire_date: values.hire_date.format('YYYY-MM-DD'),
    }

    const handlers = {
      onSuccess: () => {
        message.success(isEditing ? 'Employee updated' : 'Employee added')
        onClose()
      },
      onError: (error: Error) => showServerErrors(error, form, message.error),
    }

    if (employee) {
      update.mutate({ id: employee.id, input }, handlers)
    } else {
      create.mutate(input, handlers)
    }
  }

  return (
    <Drawer
      open={open}
      onClose={onClose}
      width={480}
      title={isEditing ? `Edit ${employee.full_name}` : 'Add employee'}
      // The form is thrown away when the drawer closes, so the next one opens
      // clean rather than holding the last person's details.
      destroyOnHidden
      footer={
        <Flex justify="flex-end" gap="small">
          <Button onClick={onClose}>Cancel</Button>
          <Button type="primary" loading={saving} onClick={() => form.submit()}>
            {isEditing ? 'Save changes' : 'Add employee'}
          </Button>
        </Flex>
      }
    >
      <Form<FormValues>
        form={form}
        layout="vertical"
        initialValues={employee ? toFormValues(employee) : undefined}
        onFinish={handleFinish}
      >
        <Form.Item
          label="Employee code"
          name="employee_code"
          rules={[{ required: true, message: 'Enter an employee code.' }]}
        >
          <Input placeholder="EMP-10001" />
        </Form.Item>

        <Flex gap="small">
          <Form.Item
            label="First name"
            name="first_name"
            style={{ flex: 1 }}
            rules={[{ required: true, message: 'Enter a first name.' }]}
          >
            <Input />
          </Form.Item>

          <Form.Item
            label="Last name"
            name="last_name"
            style={{ flex: 1 }}
            rules={[{ required: true, message: 'Enter a last name.' }]}
          >
            <Input />
          </Form.Item>
        </Flex>

        <Form.Item
          label="Email"
          name="email"
          rules={[
            { required: true, message: 'Enter an email address.' },
            { type: 'email', message: 'That does not look like an email address.' },
          ]}
        >
          <Input type="email" />
        </Form.Item>

        <Form.Item
          label="Country"
          name="country_code"
          rules={[{ required: true, message: 'Choose a country.' }]}
          extra="The country decides which currency the salary is in."
        >
          <Select
            showSearch
            optionFilterProp="label"
            options={(catalog?.countries ?? []).map((country) => ({
              value: country.code,
              label: `${country.name} (${country.currency})`,
            }))}
          />
        </Form.Item>

        <Form.Item
          label="Department"
          name="department"
          rules={[{ required: true, message: 'Choose a department.' }]}
        >
          <Select
            showSearch
            optionFilterProp="label"
            // A title only belongs to one department, so the one already
            // chosen cannot survive a change of department.
            onChange={() => form.setFieldValue('job_title', undefined)}
            options={(catalog?.departments ?? []).map((candidate) => ({
              value: candidate.name,
              label: candidate.name,
            }))}
          />
        </Form.Item>

        <Form.Item
          label="Job title"
          name="job_title"
          rules={[{ required: true, message: 'Choose a job title.' }]}
        >
          <Select
            showSearch
            optionFilterProp="label"
            disabled={!department}
            placeholder={department ? undefined : 'Choose a department first'}
            options={jobTitles.map((title) => ({ value: title, label: title }))}
          />
        </Form.Item>

        <Form.Item
          label="Level"
          name="level"
          rules={[{ required: true, message: 'Choose a level.' }]}
        >
          <Select
            options={(catalog?.levels ?? []).map((level) => ({ value: level, label: level }))}
          />
        </Form.Item>

        <Form.Item
          label="Annual salary"
          name="annual_salary"
          rules={[{ required: true, message: 'Enter an annual salary.' }]}
        >
          <InputNumber<number>
            min={1}
            precision={0}
            style={{ width: '100%' }}
            // Whole units of the country's own currency. Nothing here is ever
            // converted, so the code sits on the field itself.
            addonAfter={currency ?? '—'}
            formatter={(value) => (value === undefined ? '' : withThousands(value))}
            parser={(displayValue) => Number((displayValue ?? '').replace(/[^\d]/g, ''))}
          />
        </Form.Item>

        <Form.Item
          label="Hire date"
          name="hire_date"
          rules={[{ required: true, message: 'Choose a hire date.' }]}
        >
          <DatePicker
            style={{ width: '100%' }}
            // Nobody is hired in the future; the API refuses it too.
            disabledDate={(date) => date.isAfter(dayjs(), 'day')}
          />
        </Form.Item>
      </Form>
    </Drawer>
  )
}

function toFormValues(employee: Employee): FormValues {
  return {
    employee_code: employee.employee_code,
    first_name: employee.first_name,
    last_name: employee.last_name,
    email: employee.email,
    country_code: employee.country_code,
    department: employee.department,
    job_title: employee.job_title,
    level: employee.level,
    annual_salary: employee.annual_salary,
    hire_date: dayjs(employee.hire_date),
  }
}

/**
 * A rejected save puts each message under the field that caused it. Anything
 * the form has no field for — or a failure that is not about the data at all,
 * such as the network — is said out loud instead, so a save never fails
 * silently.
 */
function showServerErrors(
  error: Error,
  form: FormInstance<FormValues>,
  announce: (text: string) => void,
): void {
  if (!(error instanceof ApiError) || !error.fieldErrors) {
    announce(error instanceof ApiError ? error.message : 'Could not save. Please try again.')
    return
  }

  form.setFields(
    Object.entries(error.fieldErrors).map(([field, messages]) => ({
      name: field as keyof FormValues,
      errors: messages,
    })),
  )
}

function withThousands(value: number | string): string {
  return `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}
