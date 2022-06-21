if Meteor.isClient
    Template.posts.onCreated ->
        document.title = 'rv posts'
        
        Session.setDefault('current_search', null)
        Session.setDefault('porn', false)
        Session.setDefault('dummy', false)
        Session.setDefault('is_loading', false)
        @autorun => @subscribe 'doc_by_id', Session.get('full_doc_id'), ->
        @autorun => @subscribe 'agg_emotions',
            picked_tags.array()
            Session.get('dummy')
        @autorun => @subscribe 'post_tag_results',
            picked_tags.array()
            Session.get('porn')
            Session.get('dummy')
            
    Template.doc_results.onCreated ->
        @autorun => @subscribe 'doc_results',
            picked_tags.array()
            Session.get('porn')
            # Session.get('dummy')
    
    
    
    Router.route '/post/:doc_id', (->
        @layout 'layout'
        @render 'post_view'
        ), name:'post_view'
    Router.route '/posts', (->
        @layout 'layout'
        @render 'posts'
        ), name:'posts'
    Template.posts.onCreated ->
        @autorun => Meteor.subscribe 'model_counter',('post'), ->
    Template.posts.helpers
        total_post_count: -> Counts.get('model_counter') 


    Template.post_view.onCreated ->
        @autorun => @subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.post_view.onRendered ->
        # console.log @
        found_doc = Docs.findOne Router.current().params.doc_id


    Template.agg_tag.onCreated ->
        # console.log @
        @autorun => @subscribe 'tag_image', @data.name, Session.get('porn'),->
    Template.agg_tag.helpers
        term_image: ->
            # console.log Template.currentData().name
            found = Docs.findOne {
                model:'post'
                tags:$in:[Template.currentData().name]
                "watson.metadata.image":$exists:true
            }, sort:ups:-1
            # console.log 'found image', found
            found
    Template.unpick_tag.onCreated ->
        # console.log @
        @autorun => @subscribe 'tag_image', @data, Session.get('porn'),->
    Template.unpick_tag.helpers
        flat_term_image: ->
            # console.log Template.currentData()
            found = Docs.findOne {
                model:'post'
                tags:$in:[Template.currentData()]
                "watson.metadata.image":$exists:true
            }, sort:ups:-1
            # console.log 'found flat image', found.watson.metadata.image
            found.watson.metadata.image
    Template.agg_tag.events
        'click .result': (e,t)->
            # Meteor.call 'log_term', @title, ->
            picked_tags.push @name
            $('#search').val('')
            Session.set('full_doc_id', null)
            
            Session.set('current_search', null)
            Session.set('searching', true)
            Session.set('is_loading', true)
            # Meteor.call 'call_wiki', @name, ->
    
    
    Template.posts.events
        'click .toggle_porn': ->
            Session.set('porn',!Session.get('porn'))
        'click .select_search': ->
            picked_tags.push @name
            Session.set('full_doc_id', null)
    
            $('#search').val('')
            Session.set('current_search', null)
    
    Template.post_card.helpers
        five_cleaned_tags: ->
            # console.log picked_tags.array()
            # console.log @tags[..5] not in picked_tags.array()
            # console.log _.without(@tags[..5],picked_tags.array())
            if picked_tags.array().length
                _.difference(@tags[..10],picked_tags.array())
            #     @tags[..5] not in picked_tags.array()
            else 
                @tags[..5]
    Template.flat_tag_picker.events
        'click .remove_tag': ->
            # console.log @
            parent = Template.parentData()
            console.log parent
            # if confirm "remove #{@valueOf()} tag?"
            Docs.update parent._id,
                $pull:
                    tags:@valueOf()
        'click .pick_flat_tag': -> 
            picked_tags.push @valueOf()
            Session.set('full_doc_id', null)
    
            Session.set('loading',true)
    Template.post_card_big.events
        'click .minimize': ->
            Session.set('full_doc_id', null)
    Template.post_card.helpers
        upvote_class:->
            if Meteor.user()
                if @upvoter_ids and Meteor.userId() in @upvoter_ids
                    'large'
                else 
                    'outline'
        downvote_class:->
            if Meteor.user()
                if @downvoter_ids and Meteor.userId() in @downvoter_ids
                    'large'
                else 
                    'outline'
    Template.post_card.events
        'click .vote_up': ->
            if Meteor.user()
                Docs.update @_id,
                    $inc:
                        points:1
                        user_points:1
                    $addToSet:
                        upvoter_ids:Meteor.userId()
                        upvoter_usernames:Meteor.user().username
                    $pull:
                        downvoter_ids:Meteor.userId()
                        downvoter_usernames:Meteor.user().username
            else 
                Docs.update @_id,
                    $inc:
                        points:1
                        anon_points:1
            Session.set('dummy', !Session.get('dummy'))

            
        'click .vote_down': ->
            if Meteor.user()
                Docs.update @_id,
                    $inc:
                        points:-1
                        user_points:-1
                    $addToSet:
                        downvoter_ids:Meteor.userId()
                        downvoter_usernames:Meteor.user().username
                    $pull:
                        upvoter_ids:Meteor.userId()
                        upvoter_usernames:Meteor.user().username
                        
            else 
                Docs.update @_id,
                    $inc:
                        points:1
                        anon_points:1
            Session.set('dummy', !Session.get('dummy'))

        'click .expand': ->
            Session.set('full_doc_id', @_id)
            Session.set('dummy', !Session.get('dummy'))
    
        'click .pick_flat_tag': (e)-> 
            picked_tags.push @valueOf()
            Session.set('full_doc_id', null)
            $(e.currentTarget).closest('.pick_flat_tag').transition('fly up', 500)
    
            Session.set('loading',true)
    Template.unpick_tag.events
        'click .unpick_tag': ->
            picked_tags.remove @valueOf()
            console.log picked_tags.array()
            if picked_tags.array().length > 0
                Session.set('is_loading', true)
            
    
    
    Template.posts.events
        'click .print_me': ->
            console.log @
    
        # # 'keyup #search': _.throttle((e,t)->
        'click #search': (e,t)->
            if picked_tags.array().length > 0
                Session.set('dummy', !Session.get('dummy'))
        'keydown #search': (e,t)->
            # query = $('#search').val()
            search = $('#search').val().trim().toLowerCase()
            # if query.length > 0
            Session.set('current_search', search)
            # console.log Session.get('current_search')
            if search.length > 0
                if e.which is 13
                    if search.length > 0
                        # Session.set('searching', true)
                        picked_tags.push search
                        Session.set('full_doc_id',null)
                        # console.log 'search', search
                        Session.set('is_loading', true)
                        $('#search').val('')
                        $('#search').blur()
                        Session.set('current_search', null)
        # , 200)
    
        # 'keydown #search': _.throttle((e,t)->
        #     if e.which is 8
        #         search = $('#search').val()
        #         if search.length is 0
        #             last_val = picked_tags.array().slice(-1)
        #             console.log last_val
        #             $('#search').val(last_val)
        #             picked_tags.pop()
        #             Meteor.call 'search_reddit', picked_tags.array(), ->
        # , 1000)
    
        'click .reconnect': -> Meteor.reconnect()
    
        'click .toggle_tag': (e,t)-> picked_tags.push @valueOf()
        'click .print_me': (e,t)->
            console.log @
            
    Template.post_card.helpers
        unescaped: -> 
            txt = document.createElement("textarea")
            txt.innerHTML = @rd.selftext_html
            return txt.value
    
            # html.unescape(@rd.selftext_html)
        unescaped_content: -> 
            txt = document.createElement("textarea")
            txt.innerHTML = @rd.media_embed.content
            return txt.value
    
            # html.unescape(@rd.selftext_html)
    Template.post_view.events 
        'click .get_comments':->
            console.log @
            Meteor.call 'get_comments', Router.current().params.doc_id, ->
                
    Template.post_view.helpers
        comment_docs: ->
            Docs.find 
                model:'comment'
                parent_id:Router.current().params.doc_id
    Template.posts.helpers
        porn_class: ->
            if Session.get('porn') then 'large red' else 'compact'
        full_doc_id: ->
            Session.get('full_doc_id')
        full_doc: ->
            Docs.findOne Session.get('full_doc_id')
        current_bg:->
            # console.log picked_tags.array()
            found = Docs.findOne {
                model:'post'
                tags:$in:picked_tags.array()
                "watson.metadata.image":$exists:true
                # thumbnail:$nin:['default','self']
            },sort:ups:-1
            if found
                # console.log 'found bg'
                found.watson.metadata.image
            # else 
            #     console.log 'no found bg'
    
        emotion_avg_result: ->
            Results.findOne 
                model:'emotion_avg'
        # in_dev: -> Meteor.isDevelopment()
        not_searching: ->
            picked_tags.array().length is 0 and Session.equals('current_search',null)
            
        search_class: ->
            if Session.get('current_search')
                'massive active' 
            else
                if picked_tags.array().length is 0
                    'big'
                else 
                    'big' 
              
                    
        curent_date_setting: -> Session.get('date_setting')
    
        term_icon: ->
            console.log @
        is_loading: -> Session.get('is_loading')
    
        tag_result_class: ->
            # ec = omega.emotion_color
            # console.log @
            # console.log omega.total_doc_result_count
            total_doc_result_count = Docs.find({}).count()
            console.log total_doc_result_count
            percent = @count/total_doc_result_count
            # console.log 'percent', percent
            # console.log typeof parseFloat(@relevance)
            # console.log typeof (@relevance*100).toFixed()
            whole = parseInt(percent*10)+1
            # console.log 'whole', whole
    
            # if whole is 0 then "#{ec} f5"
            if whole is 0 then "f5"
            else if whole is 1 then "f11"
            else if whole is 2 then "f12"
            else if whole is 3 then "f13"
            else if whole is 4 then "f14"
            else if whole is 5 then "f15"
            else if whole is 6 then "f16"
            else if whole is 7 then "f17"
            else if whole is 8 then "f18"
            else if whole is 9 then "f19"
            else if whole is 10 then "f20"
    
        connection: ->
            # console.log Meteor.status()
            Meteor.status()
        connected: -> Meteor.status().connected
    
        unpicked_tags: ->
            # # doc_count = Docs.find().count()
            # # console.log 'doc count', doc_count
            # # if doc_count < 3
            # #     Tags.find({count: $lt: doc_count})
            # # else
            # unless Session.get('searching')
            #     unless Session.get('current_search').length > 0
            Results.find({model:'tag'})
    
        result_class: ->
            if Template.instance().subscriptionsReady()
                ''
            else
                'disabled'
    
        picked_tags: -> picked_tags.array()
    
        picked_tags_plural: -> picked_tags.array().length > 1
    
        searching: ->
            # console.log 'searching?', Session.get('searching')
            Session.get('searching')
    
        one_post: -> Docs.find().count() is 1
    
        two_posts: -> Docs.find().count() is 2
        three_posts: -> Docs.find().count() is 3
        four_posts: -> Docs.find().count() is 4
        more_than_four: -> Docs.find().count() > 4
        one_result: ->
            Docs.find().count() is 1
    
        docs: ->
            # if picked_tags.array().length > 0
            cursor =
                Docs.find {
                    model:'post'
                },
                    sort:
                        "#{Session.get('sort_key')}":Session.get('sort_direction')
            # console.log cursor.fetch()
            cursor
    
    
        home_subs_ready: ->
            Template.instance().subscriptionsReady()
            
        #     @autorun => Meteor.subscribe 'current_doc', Router.current().params.doc_id
        #     console.log @
        # Template.array_view.events
        #     'click .toggle_post_filter': ->
        #         console.log @
        #         value = @valueOf()
        #         console.log Template.currentData()
        #         current = Template.currentData()
        #         console.log Template.parentData()
                # match = Session.get('match')
                # key_array = match["#{current.key}"]
                # if key_array
                #     if value in key_array
                #         key_array = _.without(key_array, value)
                #         match["#{current.key}"] = key_array
                #         picked_tags.remove value
                #         Session.set('match', match)
                #     else
                #         key_array.push value
                #         picked_tags.push value
                #         Session.set('match', match)
                #         Meteor.call 'search_reddit', picked_tags.array(), ->
                #         # Meteor.call 'agg_idea', value, current.key, 'entity', ->
                #         console.log @
                #         # match["#{current.key}"] = ["#{value}"]
                # else
                # if value in picked_tags.array()
                #     picked_tags.remove value
                # else
                #     # match["#{current.key}"] = ["#{value}"]
                #     picked_tags.push value
                #     # console.log picked_tags.array()
                # # Session.set('match', match)
                # # console.log picked_tags.array()
                # if picked_tags.array().length > 0
                #     Meteor.call 'search_reddit', picked_tags.array(), ->
                # console.log Session.get('match')
    
        # Template.array_view.helpers
        #     values: ->
        #         # console.log @key
        #         Template.parentData()["#{@key}"]
        #
        #     post_label_class: ->
        #         match = Session.get('match')
        #         key = Template.parentData().key
        #         doc = Template.parentData(2)
        #         # console.log key
        #         # console.log doc
        #         # console.log @
        #         if @valueOf() in picked_tags.array()
        #             'active'
        #         else
        #             'basic'
        #         # if match["#{key}"]
        #         #     if @valueOf() in match["#{key}"]
        #         #         'active'
        #         #     else
        #         #         'basic'
        #         # else
        #         #     'basic'
        #
        
        
    Template.user_post.onCreated ->
        if Meteor.user()
            username = Meteor.user().username
        else 
            username = null
        @autorun => Meteor.subscribe 'overlap', 
            Router.current().params.username, 
            username, 
            picked_tags.array(),
    Template.user_post.helpers
        mined_counter: -> Counts.get('mined_counter') 
        overlap_tags: ->
            Results.find 
                model:'overlap_tag'

    Template.doc_results.helpers
        doc_results: ->
            current_docs = Docs.find()
            # if Session.get('selected_doc_id') in current_docs.fetch()
            # console.log current_docs.fetch()
            # Docs.findOne Session.get('selected_doc_id')
            doc_count = Docs.find().count()
            # if doc_count is 1
            Docs.find({model:'post'}, 
                limit:20
                sort:
                    points:-1
                    ups:-1
                    # "#{Session.get('sort_key')}":Session.get('sort_direction')
            )
    


  
if Meteor.isServer 
    Meteor.publish 'product_counter', ()->
        Counts.publish this, 'product_counter', 
            Docs.find({
                model:'product'
            })
        return undefined    # otherwise coffeescript returns a Counts.publish
                          # handle when Meteor expects a Mongo.Cursor object.
        
        
    Meteor.publish 'post_tag_results', (
        picked_tags=null
        # query
        porn=false
        # searching
        dummy
        )->
    
        self = @
        match = {}
    
        match.model = 'post'
        # if query
        # if view_nsfw
        match.over_18 = porn
        if picked_tags and picked_tags.length > 0
            match.tags = $all: picked_tags
            limit = 10
            # else
            #     limit = 10
            #     match._timestamp = $gt:moment().subtract(1, 'days')
            # else /
                # match.tags = $all: picked_tags
            agg_doc_count = Docs.find(match).count()
            tag_cloud = Docs.aggregate [
                { $match: match }
                { $project: "tags": 1 }
                { $unwind: "$tags" }
                { $group: _id: "$tags", count: $sum: 1 }
                { $match: _id: $nin: picked_tags }
                { $match: count: $lt: agg_doc_count }
                # { $match: _id: {$regex:"#{current_query}", $options: 'i'} }
                { $sort: count: -1, _id: 1 }
                { $limit: limit }
                { $project: _id: 0, name: '$_id', count: 1 }
            ], {
                allowDiskUse: true
            }
        
            tag_cloud.forEach (tag, i) =>
                self.added 'results', Random.id(),
                    name: tag.name
                    count: tag.count
                    model:'tag'
                    # index: i
            
            self.ready()
            # else []
    
    Meteor.publish 'tag_image', (
        term=null
        porn=false
        )->
        # added_tags = []
        # console.log 'match term', term
        # console.log 'match picked tags', picked_tags
        # if picked_tags.length > 0
        #     added_tags = picked_tags.push(term)
        match = {
            model:'post'
            tags: $in: [term]
            # "watson.metadata.image": $exists:true
            # $where: "this.watson.metadata.image.length > 1"
        }
        # if porn
        # else 
        # added_tags = [term]
        # match = {model:'post'}
        # match.thumbnail = $nin:['default','self']
        # match.url = { $regex: /^.*(http(s?):)([/|.|\w|\s|-])*\.(?:jpg|gif|png).*/, $options: 'i' }
        # console.log "added tags", added_tags
        # console.log 'looking up added tags', added_tags
        # found = Docs.findOne match
        # console.log "TERM", term, found.
        # if found
        #     # console.log "FOUND THUMBNAIL",found.thumbnail
        Docs.find match,{
            limit:1
            sort:
                points:-1
                ups:-1
            fields:
                image_id:1
                image_link:1
                model:1
                thumbnail:1
                tags:1
                ups:1
                over_18:1
                url:1
        }
        # else
        #     backup = 
        #         Docs.findOne 
        #             model:'post'
        #             thumbnail:$exists:true
        #             tags:$in:[term]
        #     console.log 'BACKUP', backup
        #     if backup
        #         Docs.find { 
        #             model:'post'
        #             thumbnail:$exists:true
        #             tags:$in:[term]
        #         }, 
        #             limit:1
        #             sort:ups:1
    Meteor.publish 'doc_results', (
        picked_tags=null
        sort_key='_timestamp'
        sort_direction=-1
        # dummy
        # current_query
        # date_setting
        )->
        # else
        self = @
        match = {model:'post'}
        # match.over_18 = $ne:true
        #         yesterday = now-day
        #         match._timestamp = $gt:yesterday
        # if porn
        # if picked_tags.length > 0
        #     # if picked_tags.length is 1
        #     #     found_doc = Docs.findOne(title:picked_tags[0])
        #     #
        #     #     match.title = picked_tags[0]
        #     # else
        if picked_tags and picked_tags.length > 0
            match.tags = $all: picked_tags
        else 
            match._timestamp = $gt:moment().subtract(1, 'days')
        Docs.find match,
            sort:
                "#{sort_key}":sort_direction
                points:-1
                ups:-1
            limit:20
        # else 
        #     Docs.find match,
        #         sort:_timestamp:-1
        #         limit:10
    
    
    
    Meteor.publish 'overlap', (
        username1
        username2
        picked_tags=null
        # query
        porn=false
        # searching
        dummy
        )->
    
        self = @
        match = {}
        user1 = Meteor.users.findOne username:username1
        user2 = Meteor.users.findOne username:username2
        match.model = 'post'
        # if query
        # if view_nsfw
        match.upvoter_ids = $all:[user1._id,user2._id]
        # match.over_18 = porn
        if picked_tags and picked_tags.length > 0
            match.tags = $all: picked_tags
            limit = 10
        else
            limit = 20
        # console.log 'match overlap', match, Docs.find(match).count()
        # else /
            # match.tags = $all: picked_tags
        agg_doc_count = Docs.find(match).count()
        tag_cloud = Docs.aggregate [
            { $match: match }
            { $project: "tags": 1 }
            { $unwind: "$tags" }
            { $group: _id: "$tags", count: $sum: 1 }
            { $match: _id: $nin: picked_tags }
            { $match: count: $lt: agg_doc_count }
            # { $match: _id: {$regex:"#{current_query}", $options: 'i'} }
            { $sort: count: -1, _id: 1 }
            { $limit: limit }
            { $project: _id: 0, name: '$_id', count: 1 }
        ], {
            allowDiskUse: true
        }
    
        tag_cloud.forEach (tag, i) =>
            self.added 'results', Random.id(),
                name: tag.name
                count: tag.count
                model:'overlap_tag'
                # index: i
        
        self.ready()
        # else []
if Meteor.isClient
    Template.post_view.onCreated ->
        @autorun => @subscribe 'related_group',Router.current().params.doc_id, ->
    Template.post_view.onCreated ->
        @autorun => @subscribe 'post_tips',Router.current().params.doc_id, ->
    Template.post_view.events 
        'click .pick_flat_tag': (e)-> 
            picked_tags.push @valueOf()
            # Session.set('full_doc_id', null)
            $(e.currentTarget).closest('.pick_flat_tag').transition('fly up', 500)
    
            Session.set('loading',true)
            Router.go "/posts"
        'click .get_comments': ->
            console.log @
                
                
if Meteor.isServer 
    Meteor.methods 
        find_tribe: (tribe_slug)->
            found = Docs.findOne 
                model:'tribe'
                slug:tribe_slug
            
            if found 
                console.log found 
                return found._id
            else
                new_id = 
                    Docs.insert 
                        model:'tribe'
                        title:tribe_slug
                        slug:tribe_slug
                return new_id
                    
                            
                            
                            
                
if Meteor.isClient         
    Template.tip_button.events 
        'click .tip_post': ->
            # console.log 'hi'
            new_id = 
                Docs.insert 
                    model:'transfer'
                    post_id:Router.current().params.doc_id
                    complete:true
                    amount:@amount
                    transfer_type:'tip'
                    tags:['tip']
            Meteor.call 'calc_user_points', ->
            $('body').toast(
                showIcon: 'coins'
                message: "post tipped #{amount} "
                showProgress: 'bottom'
                class: 'success'
                # displayTime: 'auto',
                position: "bottom right"
            )
                
                
if Meteor.isServer 
    Meteor.publish 'post_tips', (post_id)->
        Docs.find 
            model:'transfer'
            post_id:post_id
