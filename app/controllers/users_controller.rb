class UsersController < ApplicationController
  skip_before_filter :require_login, :only => [:index, :new, :create, :login]

  alias :sorcery_login :login
  alias :sorcery_logout :logout

  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.haml
      format.json { render :json => @user }
    end
  end

  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, :notice => 'User was successfully created.' }
        format.json { render :json => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @user = current_user

    params[:user].delete(:password) if params[:user][:password].blank?
    params[:user].delete(:password_confirmation) if params[:user][:password_confirmation].blank?

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to profile_path, :notice => 'Your profile has been updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "profile" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def login
    if request.method == "GET" # They want the login form.
      @user = User.new
    elsif request.method == "POST" # They're submitting the login form.
      respond_to do |format|
        if @user = sorcery_login(params[:username],params[:password])
          format.html { redirect_back_or_to({:controller => "home"}, :notice => 'Login successful.  Welcome.') }
          format.xml  { render :xml => @user, :status => :created, :location => @user }
        else
          format.html { flash.now[:alert] = "Login failed."; render :action => "new" }
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def logout
    sorcery_logout
    redirect_to({:controller => "home"}, :notice => 'You have been logged out.')
  end

  def profile
    @user = current_user
  end
end
