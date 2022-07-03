Docs.allow
    insert: (userId, doc) -> 
        true    
            # doc._author_id is userId
    update: (userId, doc) ->
        true
        # if doc.model in ['calculator_doc','simulated_rental_item','healthclub_session']
        #     true
        # else if Meteor.user() and Meteor.user().roles and 'admin' in Meteor.user().roles
        #     true
        # else
        #     doc._author_id is userId
    # update: (userId, doc) -> doc._author_id is userId or 'admin' in Meteor.user().roles
    remove: (userId, doc) ->
        true
        # doc._author_id is userId or 'admin' in Meteor.user().roles

Meteor.users.allow
    insert: (userId, doc) -> 
        true    
            # doc._author_id is userId
    update: (userId, doc) ->
        doc
        # if doc.model in ['calculator_doc','simulated_rental_item','healthclub_session']
        #     true
        # else if Meteor.user() and Meteor.user().roles and 'admin' in Meteor.user().roles
        #     true
        # else
        #     doc._author_id is userId
    # update: (userId, doc) -> doc._author_id is userId or 'admin' in Meteor.user().roles
    remove: (userId, doc) -> 
        if Meteor.user() and Meteor.user().admin_mode
            true
        else
            false
        # doc._author_id is userId or 'admin' in Meteor.user().roles

Meteor.publish 'count', ->
  Counts.publish this, 'product_counter', Docs.find({model:'product'})
  return undefined    # otherwise coffeescript returns a Counts.publish
                      # handle when Meteor expects a Mongo.Cursor object.


Cloudinary.config
    cloud_name: 'facet'
    api_key: Meteor.settings.private.cloudinary_key
    api_secret: Meteor.settings.private.cloudinary_secret




Meteor.publish 'author_by_id', (doc_id)->
    doc = Docs.findOne doc_id
    if doc and doc._author_id
        Meteor.users.find(doc._author_id)
    
Meteor.publish 'latest_checkin_docs', ()->
    Docs.find {
        model:'checkin'
    }, 
        sort:_timestamp:-1
        limit:10
    
Meteor.publish 'all_users_min', ()->
    Meteor.users.find({},
        fields:
            username:1
            image_id:1
            first_name:1
            last_name:1
            points:1
            tags:1
    )

Meteor.publish 'group_by_doc_id', (doc_id)->
    doc = Docs.findOne doc_id
    if doc and doc.group_id
        Docs.find {_id:doc.group_id},
            fields:
                title:1
                image_id:1
                model:1
    
Meteor.publish 'unread_logs', ()->
    if Meteor.user()
        Docs.find {
            model:'log'
            read_user_ids:$nin:[Meteor.userId()]
        },
            sort:_timestamp:-1
            limit:10
            fields:
                body:1
                _timestamp:1
                read_user_ids:1
                log_type:1
                parent_id:1
                parent_model:1
                group_id:1
                model:1
                _author_id:1
                _author_username:1
    
Meteor.publish 'all_users', (child_id)->
    Meteor.users.find()
Meteor.publish 'latest_order_docs', ()->
    Docs.find {
        model:'order'
    }, sort:_timestamp:-1
Meteor.publish 'public_posts', (child_id)->
    Docs.find {
        model:'post'
        private:$ne:true
    }, limit:20


Meteor.publish 'model_docs', (
    model
    limit=20
    )->
    Docs.find {
        model: model
        # app:'goldrun'
    }, limit:limit

Meteor.publish 'document_by_slug', (slug)->
    Docs.find
        model: 'document'
        slug:slug

Meteor.publish 'child_docs', (model,parent_id)->
    Docs.find 
        model:model
        parent_id:parent_id

Meteor.publish 'me', ()-> Meteor.users.find Meteor.userId()


Meteor.publish 'user_from_username', (username)->
    Meteor.users.find 
        username:username

Meteor.publish 'user_from_id', (user_id)->
    Meteor.users.find user_id

Meteor.publish 'doc', (doc_id)->
    Docs.find doc_id

Meteor.publish 'author_from_doc_id', (doc_id)->
    doc = Docs.findOne doc_id
    if doc 
        Docs.find doc._author_id

    
    
Meteor.methods
    log_view: (doc_id)->
        doc = Docs.findOne doc_id
        Docs.update doc_id,
            $inc:
                views:1
            $set:
                last_viewed_timestamp:Date.now()
        if Meteor.userId()
            Docs.update doc_id,
                $inc:
                    user_views:1
                $addToSet:
                    read_user_ids:Meteor.userId()
                    read_usernames:Meteor.user().username
                $set:
                    last_user_viewed_timestamp:Date.now()
            Meteor.users.update Meteor.userId(),
                $set:
                    current_viewing_doc_id:doc_id
        else 
            Docs.update doc_id,
                $inc:
                    anon_views:1
                $set:
                    last_anon_viewed_timestamp:Date.now()
        Meteor.call 'calc_user_points', ->
        Meteor.call 'calc_user_points', doc._author_id, ->

    insert_log: (type, user_id)->
        if type
            new_id = 
                Docs.insert 
                    model:'log_event'
                    log_type:type
                    user_id:user_id
    
    add_user: (username)->
        options = {}
        options.username = username
        options.password = username
        res= Accounts.createUser options
        if res
            return res
        else
            Throw.new Meteor.Error 'err creating user'


    change_username:  (user_id, new_username) ->
        user = Meteor.users.findOne user_id
        Accounts.setUsername(user._id, new_username)
        return "updated username to #{new_username}."



    lookup_user: (username_query, role_filter)->
        # if role_filter
        #     Docs.find({
        #         username: {$regex:"#{username_query}", $options: 'i'}
        #         roles:$in:[role_filter]
        #         },{limit:10}).fetch()
        # else
        Meteor.users.find({
            username: {$regex:"#{username_query}", $options: 'i'}
            },{limit:10}).fetch()


    lookup_doc: (guest_name, model_filter)->
        Docs.find({
            model:model_filter
            guest_name: {$regex:"#{guest_name}", $options: 'i'}
            },{limit:10}).fetch()


    # lookup_username: (username_query)->
    #     found_users =
    #         Docs.find({
    #             model:'person'
    #             username: {$regex:"#{username_query}", $options: 'i'}
    #             }).fetch()
    #     found_users

    # lookup_first_name: (first_name)->
    #     found_people =
    #         Docs.find({
    #             model:'person'
    #             first_name: {$regex:"#{first_name}", $options: 'i'}
    #             }).fetch()
    #     found_people
    #
    # lookup_last_name: (last_name)->
    #     found_people =
    #         Docs.find({
    #             model:'person'
    #             last_name: {$regex:"#{last_name}", $options: 'i'}
    #             }).fetch()
    #     found_people


    set_password: (user_id, new_password)->
        console.log 'setting password', user_id, new_password
        Accounts.setPassword(user_id, new_password)





    count_key: (key)->
        count = Docs.find({"#{key}":$exists:true}).count()







Meteor.publish 'doc_by_id', (doc_id)->
    Docs.find doc_id


Meteor.methods    
    global_remove: (keyname)->
        result = Docs.update({"#{keyname}":$exists:true}, {
            $unset:
                "#{keyname}": 1
                "_#{keyname}": 1
            $pull:_keys:keyname
            }, {multi:true})



    slugify: (doc_id)->
        doc = Docs.findOne doc_id
        slug = doc.title.toString().toLowerCase().replace(/\s+/g, '_').replace(/[^\w\-]+/g, '').replace(/\-\-+/g, '_').replace(/^-+/, '').replace(/-+$/,'')
        return slug
        # # Docs.update { _id:doc_id, fields:field_object },
        # Docs.update { _id:doc_id, fields:field_object },
        #     { $set: "fields.$.slug": slug }


    rename: (old, newk)->
        old_count = Docs.find({"#{old}":$exists:true}).count()
        new_count = Docs.find({"#{newk}":$exists:true}).count()
        console.log 'old count', old_count
        console.log 'new count', new_count
        result = Docs.update({"#{old}":$exists:true}, {$rename:"#{old}":"#{newk}"}, {multi:true})
        result2 = Docs.update({"#{old}":$exists:true}, {$rename:"_#{old}":"_#{newk}"}, {multi:true})

        # > Docs.update({doc_sentiment_score:{$exists:true}},{$rename:{doc_sentiment_score:"sentiment_score"}},{multi:true})
        cursor = Docs.find({newk:$exists:true}, { fields:_id:1 })

        for doc in cursor.fetch()
            Meteor.call 'key', doc._id


        # _.each(response.data.data.children, (item)->
        #     # data = item.data
        #     # len = 200
        # )
        

            
Meteor.publish 'agg_emotions', (
    # group
    picked_tags
    dummy
    # picked_time_tags
    # selected_location_tags
    # selected_people_tags
    # picked_max_emotion
    # picked_timestamp_tags
    )->
    # @unblock()
    self = @
    match = {
        model:'post'
        # group:group
        joy_percent:$exists:true
    }
        
    doc_count = Docs.find(match).count()
    if picked_tags.length > 0 then match.tags = $all:picked_tags
    # if picked_max_emotion.length > 0 then match.max_emotion_name = $all:picked_max_emotion
    # if picked_time_tags.length > 0 then match.time_tags = $all:picked_time_tags
    # if selected_location_tags.length > 0 then match.location_tags = $all:selected_location_tags
    # if selected_people_tags.length > 0 then match.people_tags = $all:selected_people_tags
    # if picked_timestamp_tags.length > 0 then match._timestamp_tags = $all:picked_timestamp_tags
    
    emotion_avgs = Docs.aggregate [
        { $match: match }
        #     # avgAmount: { $avg: { $multiply: [ "$price", "$quantity" ] } },
        { $group: 
            _id:null
            avg_sent_score: { $avg: "$doc_sentiment_score" }
            avg_joy_score: { $avg: "$joy_percent" }
            avg_anger_score: { $avg: "$anger_percent" }
            avg_sadness_score: { $avg: "$sadness_percent" }
            avg_disgust_score: { $avg: "$disgust_percent" }
            avg_fear_score: { $avg: "$fear_percent" }
        }
    ]
    emotion_avgs.forEach (res, i) ->
        self.added 'results', Random.id(),
            model:'emotion_avg'
            avg_sent_score: res.avg_sent_score
            avg_joy_score: res.avg_joy_score
            avg_anger_score: res.avg_anger_score
            avg_sadness_score: res.avg_sadness_score
            avg_disgust_score: res.avg_disgust_score
            avg_fear_score: res.avg_fear_score
    self.ready()    
        