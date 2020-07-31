def sigh_stub_spaceship_connect(inhouse: false, create_profile_app_identifier: nil, all_app_identifiers: [], profile_names: [])
  allow(Spaceship).to receive(:login).and_return(nil)
  allow(Spaceship).to receive(:client).and_return("client")
  allow(Spaceship).to receive(:select_team).and_return(nil)

  allow(Spaceship.client).to receive(:in_house?).and_return(inhouse)

  bundle_ids = all_app_identifiers.map do |id|
    Spaceship::ConnectAPI::BundleId.new("123", {
      identifier: id,
      name: id,
      seedId: "seed",
      platform: "IOS"
    })
  end

  allow(Spaceship::ConnectAPI::BundleId).to receive(:find).with(anything).and_return(nil)
  bundle_ids.each do |bundle_id|
    allow(Spaceship::ConnectAPI::BundleId).to receive(:find).with(bundle_id.identifier).and_return(bundle_id)
  end

  if create_profile_app_identifier
    bundle_id = bundle_ids.find { |b| b.identifier == create_profile_app_identifier }
    expect(Spaceship::ConnectAPI::Profile).to receive(:create).with(anything) do |value|
      profile = Spaceship::ConnectAPI::Profile.new("123", {
        name: value[:name],
        platform: "IOS"
      })
      allow(profile).to receive(:bundle_id).and_return(bundle_id)

      profile
    end
  end

  allow(Spaceship::ConnectAPI::Profile).to receive(:all).and_return(
    profile_names.map do |name|
      profile = Spaceship::ConnectAPI::Profile.new("123", {
        name: name,
        platform: "IOS"
      })
      allow(profile).to receive(:bundle_id).and_return(bundle_id)

      profile
    end
  )

  # Stubs production to only receive certs
  certificate = "certificate"
  allow(certificate).to receive(:id).and_return("id")

  certs = [Spaceship.certificate.production]
  certs.each do |current|
    allow(current).to receive(:all).and_return([certificate])
  end

  # apple_distribution also gets called for Xcode 11 profiles
  # so need to stub and empty array return
  certs = [Spaceship.certificate.apple_distribution]
  certs.each do |current|
    allow(current).to receive(:all).and_return([])
  end
end

def sigh_stub_spaceship(valid_profile = true, expect_create = false, expect_delete = false, fail_delete = false)
  profile = "profile"
  certificate = "certificate"

  profiles_after_delete = expect_delete && !fail_delete ? [] : [profile]

  expect(Spaceship).to receive(:login).and_return(nil)
  allow(Spaceship).to receive(:client).and_return("client")
  expect(Spaceship).to receive(:select_team).and_return(nil)
  expect(Spaceship.client).to receive(:in_house?).and_return(false)
  allow(Spaceship.app).to receive(:find).and_return(true)
  allow(Spaceship.provisioning_profile).to receive(:all).and_return(profiles_after_delete)

  allow(profile).to receive(:valid?).and_return(valid_profile)
  allow(profile.class).to receive(:pretty_type).and_return("pretty")
  allow(profile).to receive(:download).and_return("FileContent")
  allow(profile).to receive(:name).and_return("com.krausefx.app AppStore")

  if expect_delete
    expect(profile).to receive(:delete!)
  else
    expect(profile).to_not(receive(:delete!))
  end

  profile_type = Spaceship.provisioning_profile.app_store
  allow(profile_type).to receive(:find_by_bundle_id).and_return([profile])

  if expect_create
    expect(profile_type).to receive(:create!).and_return(profile)
  else
    expect(profile_type).to_not(receive(:create!))
  end

  # Stubs production to only receive certs
  certs = [Spaceship.certificate.production]
  certs.each do |current|
    allow(current).to receive(:all).and_return([certificate])
  end

  # apple_distribution also gets called for Xcode 11 profiles
  # so need to stub and empty array return
  certs = [Spaceship.certificate.apple_distribution]
  certs.each do |current|
    allow(current).to receive(:all).and_return([])
  end
end

def stub_request_valid_identities(resign, value)
  expect(resign).to receive(:request_valid_identities).and_return(value)
end

# Commander::Command::Options does not define sane equals behavior,
# so we need this to make testing easier
RSpec::Matchers.define(:match_commander_options) do |expected|
  match { |actual| actual.__hash__ == expected.__hash__ }
end
