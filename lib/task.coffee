if Meteor.isClient
    Template.tasks.onCreated ->
        document.title = 'rv tasks'
        
        Session.setDefault('current_search', null)
        Session.setDefault('is_loading', false)
        @autorun => @subscribe 'doc_by_id', Session.get('full_doc_id'), ->
        @autorun => @subscribe 'agg_emotions',
            picked_tags.array()
        @autorun => @subscribe 'task_tag_results',
            picked_tags.array()
            
    Template.tasks.onCreated ->
        @autorun => @subscribe 'model_docs', 'task', ->
        @autorun => @subscribe 'tasks',
            picked_tags.array()
            # Session.get('dummy')
    
    
    
    Router.route '/task/:doc_id', (->
        @layout 'layout'
        @render 'task_view'
        ), name:'task_view'
    Router.route '/task/:doc_id/edit', (->
        @layout 'layout'
        @render 'task_edit'
        ), name:'task_edit'
    Router.route '/tasks', (->
        @layout 'layout'
        @render 'tasks'
        ), name:'tasks'
    Template.tasks.onCreated ->
        @autorun => Meteor.subscribe 'model_counter',('task'), ->
            
    Template.task_edit.onCreated ->
        @autorun => @subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.task_view.onCreated ->
        @autorun => @subscribe 'doc_by_id', Router.current().params.doc_id, ->
        @autorun => @subscribe 'child_docs', Router.current().params.doc_id, ->
            
            
    Template.tasks.helpers
        total_task_count: -> Counts.get('model_counter') 
        task_docs: ->
            Docs.find 
                model:'task'
    Template.tasks.events 
        'click .new_task': ->
            new_id = 
                Docs.insert 
                    model:'task'
                    complete:false
            Router.go "/task/#{new_id}/edit"

    Template.user_tasks.onCreated ->
        @autorun => Meteor.subscribe 'model_docs', 'task', ->
    Template.user_tasks.helpers
        user_authored_tasks: ->
            user = Meteor.users.findOne username:Router.current().params.username
            Docs.find 
                model:'task'
                _author_id:user._id
        user_assigned_tasks: ->
            user = Meteor.users.findOne username:Router.current().params.username
            Docs.find 
                model:'task'
                assigned_user_id:user._id
                complete:$ne:true
        user_completed_tasks: ->
            user = Meteor.users.findOne username:Router.current().params.username
            Docs.find 
                model:'task'
                assigned_user_id:user._id
                complete:true
            
    Template.user_tasks.events 
        'click .assign_task': ->
            user = Meteor.users.findOne username:Router.current().params.username
            if user 
                new_id = 
                    Docs.insert 
                        model:'task'
                        complete:false
                        target_id:user._id
                Router.go "/task/#{new_id}/edit"



    Template.task_view.helpers 
        activity_docs: ->
            Docs.find 
                model:'log'
                parent_id:Router.current().params.doc_id
    Template.task_view.events 
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