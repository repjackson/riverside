if Meteor.isClient
    Router.route '/users', -> @render 'users'
    @picked_porn_tags = new ReactiveArray []
    Template.user_item.onCreated ->
        @autorun => Meteor.subscribe 'user_groups_small', @data.username, -> 
        
        
        
    Template.user_view.onCreated ->
        @autorun => @subscribe 'user_by_name', Router.current().params.name, ->
    Template.user_view.helpers
        current_user: ->
            Docs.findOne 
                model:'user'
    Template.users.onCreated ->
        @autorun => Meteor.subscribe 'user_counter', ->
    Template.users.onCreated ->
        Session.set('view_friends', false)
        # @autorun -> Meteor.subscribe('users')
        Session.setDefault 'limit', 42
        Session.setDefault 'sort_key', 'points'
        Session.setDefault('view_mode','grid')
        @autorun => Meteor.subscribe 'user_tags', 
            picked_user_tags.array()
            Session.get('dummy')
            , ->
        @autorun => Meteor.subscribe 'users_pub', 
            Session.get('current_search')
            picked_user_tags.array()
            Session.get('view_friends')
            Session.get('sort_key')
            Session.get('sort_direction')
            Session.get('limit')
            ->
        # @autorun => Meteor.subscribe 'user_tags', picked_user_tags.array(), ->
     
    Template.user_card.events
        'click .calc_stats': ->
            Meteor.call 'calc_user_stats', @reddit_data.name, ->
            
            # unless @details 
            #     Meteor.call 'user_details', @_id, ->
            #         console.log 'pulled user details'

        'click .flat_user_tag': ->
            # picked_user_tags.clear()
            picked_user_tags.push @valueOf()
            Meteor.call 'search_users', picked_user_tags.array(),true, ->
            
            $('body').toast({
                title: "browsing #{@valueOf()}"
                # message: 'Please see desk staff for key.'
                class : 'success'
                showIcon:'hashtag'
                # showProgress:'bottom'
                position:'bottom right'
                # className:
                #     toast: 'ui massive message'
                # displayTime: 5000
                transition:
                  showMethod   : 'zoom',
                  showDuration : 250,
                  hideMethod   : 'fade',
                  hideDuration : 250
                })
    Template.user_view.onCreated ->
        @autorun => @subscribe 'user_posts', Router.current().params.name, ->
    Template.user_view.helpers
        user_post_docs: ->
            Docs.find
                model:'reddit'
    Template.user_view.events
        'click .calc_user_stats': ->
            Meteor.call 'calc_user_stats', Router.current().params.name, ->
        'click .get_user_posts': ->
            Meteor.call 'get_user_posts', Router.current().params.name, ->
        'click .pick_flat_tag': ->
            picked_user_tags.clear()
            picked_user_tags.push @valueOf()
            Meteor.call 'search_users', picked_user_tags.array(),true, ->
            Router.go "/users"
            $('body').toast({
                title: "browsing #{@valueOf()}"
                # message: 'Please see desk staff for key.'
                class : 'success'
                showIcon:'hashtag'
                # showProgress:'bottom'
                position:'bottom right'
                # className:
                #     toast: 'ui massive message'
                # displayTime: 5000
                transition:
                  showMethod   : 'zoom',
                  showDuration : 250,
                  hideMethod   : 'fade',
                  hideDuration : 250
                })
     
            
if Meteor.isServer 
    Meteor.publish 'users_pub', (
        username_search, 
        picked_user_tags=[], 
        view_friends=false
        sort_key='points'
        sort_direction=-1
        limit=50
    )->
        match = {}
        if view_friends
            match._id = $in: Meteor.user().friend_ids
        if picked_user_tags.length > 0 then match.tags = $all:picked_user_tags 
        if username_search
            match.username = {$regex:"#{username_search}", $options: 'i'}
        Meteor.users.find(match,{ 
            limit:20, 
            sort:
                "#{sort_key}":sort_direction
            fields:
                username:1
                image_id:1
                tags:1
                points:1
                credit:1
                first_name:1
                last_name:1
                group_memberships:1
                createdAt:1
                profile_views:1
        })
            
if Meteor.isClient
    Template.users.events
        'click .toggle_friends': -> Session.set('view_friends', !Session.get('view_friends'))
        'click .pick_user_tag': -> 
            picked_user_tags.push @name
            $('body').toast({
                title: "searching #{@name}"
                # message: 'Please see desk staff for key.'
                class : 'search'
                icon:'checkmark'
                position:'bottom right'
            })
                        
            
        'click .unpick_user_tag': -> 
            picked_user_tags.remove @valueOf()
        'click .add_user': ->
            new_username = prompt('username')
            splitted = new_username.split(' ')
            formatted = new_username.split(' ').join('_').toLowerCase()
            console.log formatted
                #   return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
            Meteor.call 'add_user', formatted, (err,res)->
                console.log res
                new_user = Meteor.users.findOne res
                Meteor.users.update res,
                    $set:
                        first_name:splitted[0]
                        last_name:splitted[1]

                Router.go "/user/#{formatted}"
                $('body').toast({
                    title: "user created"
                    # message: 'Please see desk staff for key.'
                    class : 'success'
                    icon:'user'
                    position:'bottom right'
                    # className:
                    #     toast: 'ui massive message'
                    # displayTime: 5000
                    transition:
                      showMethod   : 'zoom',
                      showDuration : 250,
                      hideMethod   : 'fade',
                      hideDuration : 250
                    })
                
        'keyup .search_user': (e,t)->
            username_query = $('.search_user').val()
            if e.which is 8
                if username_query.length is 0
                    Session.set 'username_query',null
                    # Session.set 'checking_in',false
                else
                    Session.set 'username_query',username_query
            else
                Session.set 'username_query',username_query

        'click .clear_query': ->
            Session.set('username_query',null)
    
        # 'click #add_user': ->
        #     id = Docs.insert model:'person'
        #     Router.go "/person/edit/#{id}"
        # 'keyup .username_search': (e,t)->
        #     username_search = $('.username_search').val()
        #     if e.which is 8
        #         if username_search.length is 0
        #             Session.set 'username_search',null
        #             Session.set 'checking_in',false
        #         else
        #             Session.set 'username_search',username_search
        #     else
        #         Session.set 'username_search',username_search
        'keyup .user_search': (e,t)->
            val = $('.user_search').val().trim().toLowerCase()
            if val.length > 2
                # Session.set('user_search',val)
                if e.which is 13
                    # picked_user_tags.clear()
                    picked_user_tags.push val
                    $('.user_search').val('')
            
            
    Template.users.helpers
        user_count: ->  Counts.get('user_counter')
        toggle_friends_class: -> if Session.get('view_friends',true) then 'blue large' else ''
        picked_user_tags: -> picked_user_tags.array()
        all_user_tags: -> Results.find model:'user_tag'
        
        location_tags: -> Results.find model:'location_tag'
        # all_user_tags: -> Results.find model:'user_tag'
        
        one_result: ->
            # console.log 'one'
            Meteor.users.find({_id:$ne:Meteor.userId()}).count() is 1
        username_query: -> Session.get('username_query')
        user_docs: ->
            match = {}
            username_query = Session.get('username_query')
            if username_query
                match.username = {$regex:"#{username_query}", $options: 'i'}
            if picked_user_tags.array().length > 0
                match.tags = $all: picked_user_tags.array()
                
            match._id = $ne:Meteor.userId()
            Meteor.users.find(match
                # roles:$in:['resident','owner']
            ,
                # limit:Session.get('limit')
                limit:42
                sort:"#{Session.get('sort_key')}":Session.get('sort_direction')
            )
        # users: ->
        #     username_search = Session.get('username_search')
        #     Meteor.users.find({
        #         username: {$regex:"#{username_search}", $options: 'i'}
        #         # healthclub_checkedin:$ne:true
        #         # roles:$in:['resident','owner']
        #         },{ 
        #             limit:100
        #             sort:"#{Session.get('sort_key')}":Session.get('sort_direction')
        #     })


if Meteor.isServer
    Meteor.publish 'user_tags', (
        picked_tags
        picked_porn_tags
        )->
        # user = Meteor.users.findOne @userId
        # current_herd = user.profile.current_herd
    
        self = @
        match = {model:'user'}
    
        # picked_tags.push current_herd
        if picked_tags.length > 0
            match.tags = $all: picked_tags
        if picked_porn_tags.length > 0 then match['reddit_data.subreddit.over_18'] = $all:picked_porn_tags 
            
        count = Meteor.users.find(match).count()
        cloud = Meteor.users.aggregate [
            { $match: match }
            { $project: tags: 1 }
            { $unwind: "$tags" }
            { $group: _id: '$tags', count: $sum: 1 }
            { $match: _id: $nin: picked_tags }
            { $sort: count: -1, _id: 1 }
            { $match: count: $lt: count }
            { $limit: 20 }
            { $project: _id: 0, name: '$_id', count: 1 }
            ]
        cloud.forEach (tag, i) ->
    
            self.added 'results', Random.id(),
                name: tag.name
                count: tag.count
                model:'user_tag'
                index: i
        location_cloud = Meteor.users.aggregate [
            { $match: match }
            { $project: location_tags: 1 }
            { $unwind: "$location_tags" }
            { $group: _id: '$location_tags', count: $sum: 1 }
            { $match: _id: $nin: picked_tags }
            { $sort: count: -1, _id: 1 }
            { $match: count: $lt: count }
            { $limit: 20 }
            { $project: _id: 0, name: '$_id', count: 1 }
            ]
        location_cloud.forEach (tag, i) ->
            self.added 'results', Random.id(),
                name: tag.name
                count: tag.count
                model:'location_tag'
                index: i

        self.ready()
        
        
        
if Meteor.isServer 
    Meteor.methods
        calc_user_tags: (user_id)->
            debit_tags = Meteor.call 'omega', user_id, 'debit'
            # debit_tags = Meteor.call 'omega', user_id, 'debit', (err, res)->
            # console.log res
            # console.log 'res from async agg'
            Meteor.users.update user_id, 
                $set:
                    debit_tags:debit_tags
    
            credit_tags = Meteor.call 'omega', user_id, 'credit'
            # console.log res
            # console.log 'res from async agg'
            Meteor.users.update user_id, 
                $set:
                    credit_tags:credit_tags
    
    
        omega: (user_id, direction)->
            user = Meteor.users.findOne user_id
            options = {
                explain:false
                allowDiskUse:true
            }
            match = {}
            match.model = 'debit'
            if direction is 'debit'
                match._author_id = user_id
            if direction is 'credit'
                match.target_id = user_id
    
            console.log 'found debits', Docs.find(match).count()
            # if omega.selected_tags.length > 0
            #     limit = 42
            # else
            # limit = 10
            # console.log 'omega_match', match
            # { $match: tags:$all: omega.selected_tags }
            pipe =  [
                { $match: match }
                { $project: tags: 1 }
                { $unwind: "$tags" }
                { $group: _id: "$tags", count: $sum: 1 }
                # { $match: _id: $nin: omega.selected_tags }
                { $sort: count: -1, _id: 1 }
                { $limit: 42 }
                { $project: _id: 0, title: '$_id', count: 1 }
            ]
    
            if pipe
                agg = global['Docs'].rawCollection().aggregate(pipe,options)
                # else
                res = {}
                if agg
                    agg.toArray()
                    printed = console.log(agg.toArray())
                    # console.log(agg.toArray())
                    # omega = Docs.findOne model:'omega_session'
                    # Docs.update omega._id,
                    #     $set:
                    #         agg:agg.toArray()
            else
                return null
            
            
            


if Meteor.isServer
    Meteor.publish 'user_search', (username, role)->
        if role
            Meteor.users.find({
                username: {$regex:"#{username}", $options: 'i'}
                roles:$in:[role]
            },{ limit:150})
        else
            Meteor.users.find({
                username: {$regex:"#{username}", $options: 'i'}
            },{ limit:150})
            
            
    Meteor.publish 'user_counter', ()->
        Counts.publish this, 'user_counter', 
            Docs.find({
                model:'user'
            })
        return undefined    # otherwise coffeescript returns a Counts.publish
                          # handle when Meteor expects a Mongo.Cursor object.
            