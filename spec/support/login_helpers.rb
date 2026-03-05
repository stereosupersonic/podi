module LoginHelpers
  DEFAULT_TEST_PASSWORD = "Test123!"

  def login_as(user, password: DEFAULT_TEST_PASSWORD)
    if Capybara.current_driver == :rack_test
      rack_test_login(user, password)
    else
      browser_login(user, password)
    end
  end

  private

  def rack_test_login(user, password)
    page.driver.post "/login", email: user.email, password: password
  end

  def browser_login(user, password)
    visit "/login"
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_on "Sign In"
  end
end
