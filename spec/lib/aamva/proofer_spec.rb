require 'spec_helper'
require 'ostruct'

describe Aamva::Proofer do
  let(:aamva_applicant) do
    Aamva::Applicant.from_proofer_applicant(
      OpenStruct.new(state_id_data)
    )
  end
  let(:aamva_response) { instance_double(Aamva::Response::VerificationResponse) }
  let(:verification_client) { Aamva::VerificationClient.new }
  let(:state_id_data) do
    {
      state_id_number: '1234567890',
      state_id_jurisdiction: 'VA',
      state_id_type: 'drivers_license',
    }
  end
  let(:success) { true }
  let(:verification_results) do
    {
      state_id_number: true,
      dob: true,
      last_name: true,
      last_name_fuzzy: true,
      last_name_fuzzy_alternative: true,
      first_name: true,
      first_name_fuzzy: true,
      first_name_fuzzy_alternative: true,
    }
  end
  let(:result) { Proofer::Result.new }

  subject do
    described_class.new
  end

  before do
    allow(Aamva::VerificationClient).to receive(:new).and_return(verification_client)
    allow(verification_client).to receive(:send_verification_request).with(
      applicant: aamva_applicant
    ).and_return(aamva_response)
    allow(aamva_response).to receive(:success?).and_return(success)
    allow(aamva_response).to receive(:verification_results).and_return(verification_results)
  end

  describe '#aamva_proof' do
    context 'when verification is successful' do
      it 'the result be successful' do
        subject.aamva_proof(state_id_data, result)

        expect(result.success?).to eq(true)
        expect(result.errors).to be_empty
      end
    end

    context 'when verification is unsuccessful' do
      let(:success) { false }
      let(:verification_results) { super().merge(dob: false, zipcode: false) }

      it 'the result should be failed' do
        subject.aamva_proof(state_id_data, result)

        expect(result.failed?).to eq(true)
        expect(result.errors).to eq(dob: ['UNVERIFIED'], zipcode: ['UNVERIFIED'])
      end
    end

    context 'when verification attributes are missing' do
      let(:success) { false }
      let(:verification_results) { super().merge(dob: false, zipcode: nil) }

      it 'the result should be failed' do
        subject.aamva_proof(state_id_data, result)

        expect(result.failed?).to eq(true)
        expect(result.errors).to eq(dob: ['UNVERIFIED'], zipcode: ['MISSING'])
      end
    end
  end

  describe '#proof' do
    context 'when verification is successful' do
      let(:applicant_data) do
        {
          uuid: SecureRandom.hex(32),
          dob: '19800101',
          last_name: 'Simpson',
          first_name: 'Homer',
          address1: '123 Street St',
          city: 'Springfield',
          state: 'IL',
          zipcode: '12345',
        }
      end

      let(:aamva_applicant) do
        Aamva::Applicant.from_proofer_applicant(
          OpenStruct.new(state_id_data.merge(applicant_data))
        )
      end

      it 'the result be successful' do
        result = subject.proof(state_id_data.merge(applicant_data))
        expect(result.success?).to eq(true)
        expect(result.errors).to be_empty
      end
    end
  end
end
