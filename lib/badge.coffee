if Meteor.isClient
    Template.badges.onCreated ->
        document.title = 'rv badges'
        
        Session.setDefault('current_search', null)
        Session.setDefault('is_loading', false)
        @autorun => @subscribe 'doc_by_id', Session.get('full_doc_id'), ->
        @autorun => @subscribe 'agg_emotions',
            picked_tags.array()
        @autorun => @subscribe 'badge_tag_results',
            picked_tags.array()
            
    Template.badges.onCreated ->
        @autorun => @subscribe 'model_docs', 'badge', ->
        @autorun => @subscribe 'badges',
            picked_tags.array()
            # Session.get('dummy')
    
    
    
    Router.route '/badge/:doc_id', (->
        @layout 'layout'
        @render 'badge_view'
        ), name:'badge_view'
    Router.route '/badge/:doc_id/edit', (->
        @layout 'layout'
        @render 'badge_edit'
        ), name:'badge_edit'
    Router.route '/badges', (->
        @layout 'layout'
        @render 'badges'
        ), name:'badges'
    Template.badges.onCreated ->
        @autorun => Meteor.subscribe 'model_counter',('badge'), ->
            
    Template.badge_edit.onCreated ->
        @autorun => @subscribe 'doc_by_id', Router.current().params.doc_id, ->

    Template.badge_view.onCreated ->
        @autorun => @subscribe 'doc_by_id', Router.current().params.doc_id, ->
        @autorun => @subscribe 'child_docs', Router.current().params.doc_id, ->
            
            
    Template.badges.helpers
        total_badge_count: -> Counts.get('model_counter') 
        badge_docs: ->
            Docs.find 
                model:'badge'
    Template.badges.events 
        'click .new_badge': ->
            new_id = 
                Docs.insert 
                    model:'badge'
                    complete:false
            Router.go "/badge/#{new_id}/edit"

    Template.badge_item.events
        'click .mark_viewed': ->
            unless @viewer_ids and Meteor.userId() in @viewer_ids
                Docs.update @_id, 
                    $addToSet:
                        viewer_ids:Meteor.userId()
                        viewer_usernames:Meteor.user().username
                    $set:
                        last_viewed:Date.now()
                    $inc:
                        views:1
                $('body').toast({
                    title: "mark viewed"
                    # message: 'Please see desk staff for key.'
                    class : 'black'
                    showIcon: 'eye'
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
            
    Template.user_badges.onCreated ->
        @autorun => Meteor.subscribe 'model_docs', 'badge', ->
    Template.user_badges.helpers
        user_authored_badges: ->
            user = Meteor.users.findOne username:Router.current().params.username
            Docs.find 
                model:'badge'
                _author_id:user._id
        user_assigned_badges: ->
            user = Meteor.users.findOne username:Router.current().params.username
            Docs.find 
                model:'badge'
                assigned_user_id:user._id
                complete:$ne:true
        user_completed_badges: ->
            user = Meteor.users.findOne username:Router.current().params.username
            Docs.find 
                model:'badge'
                assigned_user_id:user._id
                complete:true
            
    Template.user_badges.events 
        'click .assign_badge': ->
            user = Meteor.users.findOne username:Router.current().params.username
            if user 
                new_id = 
                    Docs.insert 
                        model:'badge'
                        complete:false
                        target_id:user._id
                Router.go "/badge/#{new_id}/edit"



    Template.badge_view.helpers 
        activity_docs: ->
            Docs.find 
                model:'log'
                parent_id:Router.current().params.doc_id
    Template.badge_view.events 
        'click .clone_badge': ->
            new_id = 
                Docs.insert 
                    model:'badge'
                    title:@title
                    image_id:@image_id
                    tags:@tags
                    parent_id:@_id
                    group_id:@group_id
            Router.go "/badge/#{new_id}/edit"
        'click .mark_complete': ->
            Docs.update Router.current().params.doc_id, 
                $set:
                    complete:true 
                    complete_timestamp: Date.now()
            Docs.insert 
                model:'log'
                parent_id:Router.current().params.doc_id 
                body:'marked complete'
                
        'click .mark_incomplete': ->
            Docs.update Router.current().params.doc_id, 
                $set:
                    complete:false 
                $unset:
                    complete_timestamp:1
            Docs.insert 
                model:'log'
                parent_id:Router.current().params.doc_id 
                body:'marked incomplete'
                
                
if Meteor.isServer
    Meteor.publish 
        child_docs: (parent_id)->
            Docs.find 
                parent_id:parent_id