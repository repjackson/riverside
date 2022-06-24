if Meteor.isClient
    Template.transfers.onCreated ->
        document.title = 'rv transfers'
        
        Session.setDefault('current_search', null)
        Session.setDefault('porn', false)
        Session.setDefault('dummy', false)
        Session.setDefault('is_loading', false)
        @autorun => @subscribe 'doc_by_id', Session.get('full_doc_id'), ->
        @autorun => @subscribe 'agg_emotions',
            picked_tags.array()
        @autorun => @subscribe 'transfer_tag_results',
            picked_tags.array()
            
    Template.transfers.onCreated ->
        @autorun => @subscribe 'model_docs', 'transfer', ->
        @autorun => @subscribe 'transfers',
            picked_tags.array()
            # Session.get('dummy')
    
    
    
    Router.route '/transfer/:doc_id', (->
        @layout 'layout'
        @render 'transfer_view'
        ), name:'transfer_view'
    Router.route '/transfer/:doc_id/edit', (->
        @layout 'layout'
        @render 'transfer_edit'
        ), name:'transfer_edit'
    Router.route '/transfers', (->
        @layout 'layout'
        @render 'transfers'
        ), name:'transfers'
    Template.transfers.onCreated ->
        @autorun => Meteor.subscribe 'model_counter',('transfer'), ->
    Template.transfers.helpers
        total_transfer_count: -> Counts.get('model_counter') 
        transfer_docs: ->
            Docs.find 
                model:'transfer'
    Template.transfers.events 
        'click .new_transfer': ->
            new_id = 
                Docs.insert 
                    model:'transfer'
                    complete:false
            Router.go "/transfer/#{new_id}/edit"

    Template.transfer_view.onCreated ->
        @autorun => @subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.transfer_view.onRendered ->
        # console.log @
        found_doc = Docs.findOne Router.current().params.doc_id


    Template.agg_tag.onCreated ->
        # console.log @
        @autorun => @subscribe 'tag_image', @data.name, Session.get('porn'),->
    Template.agg_tag.helpers
        term_image: ->
            # console.log Template.currentData().name
            found = Docs.findOne {
                model:'transfer'
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
                model:'transfer'
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
    
    
    Template.transfers.events
        'click .select_search': ->
            picked_tags.push @name
            Session.set('full_doc_id', null)
    
            $('#search').val('')
            Session.set('current_search', null)
    
    Template.transfer_card.helpers
        five_cleaned_tags: ->
            # console.log picked_tags.array()
            # console.log @tags[..5] not in picked_tags.array()
            # console.log _.without(@tags[..5],picked_tags.array())
            if picked_tags.array().length
                _.difference(@tags[..10],picked_tags.array())
            #     @tags[..5] not in picked_tags.array()
            else 
                @tags[..5]


if Meteor.isClient
    Template.transfer_view.onCreated ->
        @autorun => Meteor.subscribe 'product_from_transfer_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'author_from_doc_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.transfer_card.onCreated ->
        @autorun => Meteor.subscribe 'target_from_doc_id', (@data._id), ->
        
    Template.transfer_view.onRendered ->



if Meteor.isServer
    Meteor.publish 'user_info_min', ->
        Meteor.users.find {},
            fields: 
                username:1
                first_name:1
                last_name:1
                image_id:1
    Meteor.publish 'product_from_transfer_id', (transfer_id)->
        transfer = Docs.findOne transfer_id
        Docs.find 
            _id:transfer.product_id
if Meteor.isClient
    Template.transfer_edit.onCreated ->
        @autorun => Meteor.subscribe 'target_from_transfer_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'author_from_doc_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->

    Template.transfer_view.helpers
        _target: ->
            transfer = Docs.findOne Router.current().params.doc_id
            if transfer and transfer.target_id
                Meteor.users.findOne
                    _id: transfer.target_id

    Template.transfer_edit.helpers
        # terms: ->
        #     Terms.find()
        suggestions: ->
            Results.find(model:'tag')
        _target: ->
            transfer = Docs.findOne Router.current().params.doc_id
            if transfer and transfer.target_id
                Meteor.users.findOne
                    _id: transfer.target_id
        members: ->
            transfer = Docs.findOne Router.current().params.doc_id
            Meteor.users.find({
                # levels: $in: ['member','domain']
                _id: $ne: Meteor.userId()
            }, {
                sort:points:1
                limit:10
                })
        # subtotal: ->
        #     transfer = Docs.findOne Router.current().params.doc_id
        #     transfer.amount*transfer.target_ids.length
        
        point_max: ->
            if Meteor.user().username is 'one'
                1000
            else 
                Meteor.user().points
        
        can_submit: ->
            transfer = Docs.findOne Router.current().params.doc_id
            transfer.amount and transfer.target_id
    Template.transfer_edit.events
        'click .cancel': ->
            if confirm 'cancel?'
                Docs.remove @_id
                Router.go "/transfers"
        'click .submit': ->
            Meteor.call 'send_transfer', @_id, =>
                $('body').toast({
                    title: "transfer sent"
                    # message: 'Please see desk staff for key.'
                    class : 'info'
                    icon:'remove'
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
                Router.go "/transfer/#{@_id}"



if Meteor.isServer
    Meteor.publish 'author_from_doc_id', (doc_id)->
        doc = Docs.findOne doc_id
        if doc
            Meteor.users.find doc._author_id
    Meteor.publish 'target_from_doc_id', (transfer_id)->
        transfer = Docs.findOne transfer_id
        if transfer
            Meteor.users.find transfer.target_id
    Meteor.methods
        send_transfer: (transfer_id)->
            transfer = Docs.findOne transfer_id
            target = Meteor.users.findOne transfer.target_id
            transferer = Meteor.users.findOne transfer._author_id

            console.log 'sending transfer', transfer
            Meteor.call 'calc_user_stats', target._id, ->
            Meteor.call 'calc_user_stats', transfer._author_id, ->
    
            Docs.update transfer_id,
                $set:
                    submitted:true
                    published:true
                    submitted_timestamp:Date.now()
            return                    
