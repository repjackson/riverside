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
