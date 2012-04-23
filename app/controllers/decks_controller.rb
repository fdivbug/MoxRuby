class DecksController < ApplicationController
  layout Proc.new{ action_name == "edit" ? 'deck_editor' : 'application' }

  def index
    @title = "Decks"
    @decks = Deck.find_all_by_user_id(current_user.id)

    respond_to do |format|
      format.html # index.html.haml
      format.json { render :json => @decks }
    end
  end

  def new
    @title = "Decks"
    @deck = Deck.new

    respond_to do |format|
      format.html # new.html.haml
      format.json { render :json => @deck }
    end

  end

  def create
    @deck = Deck.new(params[:deck])
    @deck.user = current_user

    respond_to do |format|
      if @deck.save
        format.html { redirect_to edit_deck_path(@deck.id) }
        format.json { render :json => @deck, :status => :created, :location => @deck }
      else
        format.html { render :action => "new" }
        format.json { render :json => @deck.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    if params[:id].nil?
      @deck = Deck.new
    else
      @deck = Deck.find(params[:id])
    end
    @cards = Card.find(:all, :order => "name")
  end

  def destroy
    @deck = Deck.find(params[:id])
    @deck.destroy

    respond_to do |format|
      format.html { redirect_to decks_url }
      format.json { head :no_content }
    end
  end
end
