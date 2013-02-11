class ReviewsController

  MODEL = LinkedData::Models::Review

  def self.find_reviews(params)
    ont = params[:acronym]
    user = params[:username]
    return MODEL.where :ontologyReviewed => { :acronym => ont }, :user => { :username => user }
  end

  namespace "/reviews" do
    # Return an array of all reviews.
    get do
      reply MODEL.all
    end
  end

  # Handle ontology-specific reviews
  namespace "/ontologies/:acronym/reviews" do

    # Return an array of reviews for an ontology acronym.
    get do
      reply MODEL.where :ontologyReviewed => { :acronym => params[:acronym] }
    end

    # Return an array of reviews by a user for an ontology.
    get '/:username' do
      reviews = find_reviews(params) # an array of reviews
      if reviews.empty?
        error 404, "No reviews found for ontology:#{params[:acronym]}, by user:#{params[:username]}."
      end
      reply 200, reviews
    end

    # Create a new review for an ontology by a user.
    put '/:username' do
      reviews = find_reviews(params) # an array of reviews
      if not reviews.empty?
        error 409, "Reviews already exist for ontology:#{params[:acronym]}, by user:#{params[:username]}. Update using PATCH instead of PUT."
      end
      review = instance_from_params(MODEL, params)
      if review.valid?
        review.save
        reply 201, review
      else
        error 422, review.errors
      end
    end

    # Update an existing submission of a review by a user.
    patch '/:username' do
      reviews = find_reviews(params) # an array of reviews
      if reviews.empty?
        error 404, "No reviews found for ontology:#{params[:acronym]}, by user:#{params[:username]}.  Use PUT, not PATCH, to submit new reviews."
      end
      if reviews.length != 1
        error 500, "Internal error - too many reviews for ontology:#{params[:acronym]}, by user:#{params[:username]}."
      end
      review = populate_from_params(reviews[0], params)
      if review.valid?
        review.save
        halt 204
      else
        error 422, review.errors
      end
    end

    # Delete a review for an ontology by a user.
    delete '/:username' do
      reviews = find_reviews(params) # an array of reviews
      if reviews.empty?
        error 404, "No reviews found for ontology:#{params[:acronym]}, by user:#{params[:username]}."
      else
        # Note: reviews.length should always be 1, but use iteration to clear all the possible items
        # because the 4store triple store does not explicitly constrain triples to unique values.
        reviews.each {|r| r.delete }
        halt 204
      end
    end

  end
end

