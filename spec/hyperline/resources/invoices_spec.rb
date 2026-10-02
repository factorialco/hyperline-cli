# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyperline::Resources::Invoices do
  let(:client) { build_client }
  let(:invoices) { client.invoices }

  describe '#list' do
    it 'returns a collection of invoices' do
      stub_api(:get, '/v1/invoices', body: fixture('invoices_list'))

      result = invoices.list

      expect(result).to be_a(Hyperline::Collection)
      expect(result.data.length).to eq(1)
      expect(result.data.first['id']).to eq('inv_001')
    end
  end

  describe '#get' do
    it 'returns an invoice' do
      stub_api(:get, '/v1/invoices/inv_001', body: fixture('invoice'))

      result = invoices.get('inv_001')

      expect(result['id']).to eq('inv_001')
      expect(result['status']).to eq('draft')
    end
  end

  describe '#create' do
    it 'creates an invoice' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices')
             .with(body: { customer_id: 'cus_001' }.to_json)
             .to_return(
               status: 201,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'inv_002', status: 'draft' }.to_json
             )

      result = invoices.create(customer_id: 'cus_001')

      expect(stub).to have_been_requested
      expect(result['id']).to eq('inv_002')
    end
  end

  describe '#update' do
    it 'uses PATCH' do
      stub = stub_request(:patch, 'https://api.hyperline.co/v1/invoices/inv_001')
             .with(body: { memo: 'Updated' }.to_json)
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'inv_001', memo: 'Updated' }.to_json
             )

      result = invoices.update('inv_001', memo: 'Updated')

      expect(stub).to have_been_requested
      expect(result['memo']).to eq('Updated')
    end
  end

  describe '#delete' do
    it 'deletes a draft invoice' do
      stub = stub_api(:delete, '/v1/invoices/inv_001', status: 204, body: '')

      invoices.delete('inv_001')

      expect(stub).to have_been_requested
    end
  end

  describe '#validate' do
    it 'validates an invoice' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices/inv_001/validate')
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'inv_001', status: 'to_pay' }.to_json
             )

      result = invoices.validate('inv_001')

      expect(stub).to have_been_requested
      expect(result['status']).to eq('to_pay')
    end
  end

  describe '#charge' do
    it 'sends the body and the idempotency key' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices/inv_001/charge')
             .with(body: { payment_method_id: 'pm_1', amount: 500 }.to_json,
                   headers: { 'Idempotency-Key' => 'key-1' })
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      invoices.charge('inv_001', payment_method_id: 'pm_1', amount: 500, idempotency_key: 'key-1')

      expect(stub).to have_been_requested
    end

    it 'sends no Idempotency-Key when none is given' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices/inv_001/charge')
             .with { |req| !req.headers.key?('Idempotency-Key') }
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '{}')

      invoices.charge('inv_001')

      expect(stub).to have_been_requested
    end

    it 'charges an invoice' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices/inv_001/charge')
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'inv_001', status: 'paid' }.to_json
             )

      result = invoices.charge('inv_001')

      expect(stub).to have_been_requested
      expect(result['status']).to eq('paid')
    end
  end

  describe '#void' do
    it 'voids an invoice' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices/inv_001/void')
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'inv_001', status: 'voided' }.to_json
             )

      result = invoices.void('inv_001')

      expect(stub).to have_been_requested
      expect(result['status']).to eq('voided')
    end
  end

  describe '#create_credit_note' do
    it 'creates a credit note' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices/inv_001/credit-notes')
             .with(body: { reason: 'Duplicate' }.to_json)
             .to_return(
               status: 201,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'cn_001', invoice_id: 'inv_001' }.to_json
             )

      result = invoices.create_credit_note('inv_001', reason: 'Duplicate')

      expect(stub).to have_been_requested
      expect(result['id']).to eq('cn_001')
    end
  end

  describe '#mark_uncollectible' do
    it 'marks invoice as uncollectible' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices/inv_001/uncollectible')
             .to_return(
               status: 200,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'inv_001', status: 'uncollectible' }.to_json
             )

      result = invoices.mark_uncollectible('inv_001')

      expect(stub).to have_been_requested
      expect(result['status']).to eq('uncollectible')
    end
  end

  describe '#create_transaction' do
    it 'creates a transaction' do
      stub = stub_request(:post, 'https://api.hyperline.co/v1/invoices/inv_001/transactions')
             .with(body: { amount: 5000 }.to_json)
             .to_return(
               status: 201,
               headers: { 'Content-Type' => 'application/json' },
               body: { id: 'tx_001', amount: 5000 }.to_json
             )

      result = invoices.create_transaction('inv_001', amount: 5000)

      expect(stub).to have_been_requested
      expect(result['id']).to eq('tx_001')
    end
  end

  describe '#delete_transaction' do
    it 'deletes a transaction' do
      stub = stub_request(:delete, 'https://api.hyperline.co/v1/invoices/inv_001/transactions/tx_001')
             .to_return(
               status: 204,
               headers: { 'Content-Type' => 'application/json' },
               body: ''
             )

      invoices.delete_transaction('inv_001', 'tx_001')

      expect(stub).to have_been_requested
    end
  end

  describe 'pagination' do
    it 'supports each_page' do
      page1 = { meta: { total: 3, taken: 2, skipped: 0 }, data: [{ id: 'inv_001' }, { id: 'inv_002' }] }
      page2 = { meta: { total: 3, taken: 1, skipped: 2 }, data: [{ id: 'inv_003' }] }

      stub_api(:get, '/v1/invoices', body: page1)
      stub_api(:get, '/v1/invoices', body: page2, query: { 'skip' => '2' })

      pages = invoices.list.each_page.to_a

      expect(pages.length).to eq(2)
      expect(pages.first.data.length).to eq(2)
      expect(pages.last.data.length).to eq(1)
    end

    it 'supports auto_paginate' do
      page1 = { meta: { total: 3, taken: 2, skipped: 0 }, data: [{ id: 'inv_001' }, { id: 'inv_002' }] }
      page2 = { meta: { total: 3, taken: 1, skipped: 2 }, data: [{ id: 'inv_003' }] }

      stub_api(:get, '/v1/invoices', body: page1)
      stub_api(:get, '/v1/invoices', body: page2, query: { 'skip' => '2' })

      all_items = invoices.list.auto_paginate.to_a

      expect(all_items.length).to eq(3)
      expect(all_items.map { |i| i['id'] }).to eq(%w[inv_001 inv_002 inv_003])
    end
  end

  describe '#list_v2' do
    it 'sends customer_id to /v2/invoices' do
      stub = stub_api(:get, '/v2/invoices', query: { 'customer_id' => 'cus_001', 'limit' => '2' },
                                            body: { data: [{ id: 'inv_001' }], next_cursor: nil, has_more: false })

      result = invoices.list_v2(customer_id: 'cus_001', limit: 2)

      expect(stub).to have_been_requested
      expect(result).to be_a(Hyperline::CursorCollection)
      expect(result.data.first['id']).to eq('inv_001')
      expect(result.next_page?).to be(false)
      expect(result.next_page).to be_nil
    end

    it 'pages across two pages by cursor' do
      stub_api(:get, '/v2/invoices', query: { 'customer_id' => 'cus_001' },
                                     body: { data: [{ id: 'inv_001' }, { id: 'inv_002' }],
                                             next_cursor: 'c2', has_more: true })
      stub_api(:get, '/v2/invoices', query: { 'customer_id' => 'cus_001', 'cursor' => 'c2' },
                                     body: { data: [{ id: 'inv_003' }], next_cursor: nil, has_more: false })

      pages = invoices.list_v2(customer_id: 'cus_001').each_page.to_a
      all = invoices.list_v2(customer_id: 'cus_001').auto_paginate.map { |i| i['id'] }

      expect(pages.map { |p| p.data.length }).to eq([2, 1])
      expect(all).to eq(%w[inv_001 inv_002 inv_003])
    end

    it 'reads the cursor from a meta object' do
      stub_api(:get, '/v2/invoices', body: { data: [], meta: { next_cursor: 'c9', has_more: true } })

      expect(invoices.list_v2.next_cursor).to eq('c9')
    end

    it 'treats a cursor without has_more as another page' do
      stub_api(:get, '/v2/invoices', body: { data: [], next_cursor: 'c2' })

      expect(invoices.list_v2.next_page?).to be(true)
    end
  end

  describe '#get_v2' do
    it 'gets /v2/invoices/{id}' do
      stub = stub_api(:get, '/v2/invoices/inv_001', body: { id: 'inv_001' })

      expect(invoices.get_v2('inv_001')['id']).to eq('inv_001')
      expect(stub).to have_been_requested
    end
  end

  describe '#download' do
    it 'returns the bytes with content type and filename' do
      stub = stub_request(:get, 'https://api.hyperline.co/v2/invoices/inv_001/download')
             .with(query: { 'lang' => 'en',
                            'locale' => 'en-GB' }, headers: { 'Authorization' => 'Bearer test_key_123' })
             .to_return(status: 200,
                        headers: { 'Content-Type' => 'application/pdf',
                                   'Content-Disposition' => 'attachment; filename="inv_001.pdf"' },
                        body: '%PDF-1.4 fake content')

      result = invoices.download('inv_001', lang: 'en', locale: 'en-GB')

      expect(stub).to have_been_requested
      expect(result).to be_a(Hyperline::Download)
      expect(result.body).to eq('%PDF-1.4 fake content')
      expect(result.content_type).to eq('application/pdf')
      expect(result.filename).to eq('inv_001.pdf')
      expect(result.to_str).to include('%PDF')
    end

    it 'follows a 302 once without sending the Authorization header' do
      stub_request(:get, 'https://api.hyperline.co/v2/invoices/inv_001/download')
        .to_return(status: 302, headers: { 'Location' => 'https://files.example.com/tmp/abc.pdf?sig=1' })
      redirected = stub_request(:get, 'https://files.example.com/tmp/abc.pdf?sig=1')
                   .with { |req| !req.headers.key?('Authorization') }
                   .to_return(status: 200, headers: { 'Content-Type' => 'application/pdf' }, body: '%PDF-redirected')

      result = invoices.download('inv_001')

      expect(redirected).to have_been_requested
      expect(result.body).to eq('%PDF-redirected')
      expect(result.filename).to be_nil
    end

    it 'raises NotFoundError on 404' do
      stub_api(:get, '/v2/invoices/missing/download', status: 404, body: { message: 'nope' })

      expect { invoices.download('missing') }.to raise_error(Hyperline::NotFoundError)
    end
  end
end
