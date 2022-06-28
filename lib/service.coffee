if Meteor.isClient
    Template.services.onCreated ->
        document.title = 'rv services'
        
        Session.setDefault('current_search', null)
        Session.setDefault('is_loading', false)
        @autorun => @subscribe 'doc_by_id', Session.get('full_doc_id'), ->
        @autorun => @subscribe 'agg_emotions',
            picked_tags.array()
        @autorun => @subscribe 'service_tag_results',
            picked_tags.array()
            
    Template.services.onCreated ->
        @autorun => @subscribe 'model_docs', 'service', ->
        @autorun => @subscribe 'services',
            picked_tags.array()
            # Session.get('dummy')
    
    
    
    Router.route '/service/:doc_id', (->
        @layout 'layout'
        @render 'service_view'
        ), name:'service_view'
    Router.route '/service/:doc_id/edit', (->
        @layout 'layout'
        @render 'service_edit'
        ), name:'service_edit'
    Router.route '/services', (->
        @layout 'layout'
        @render 'services'
        ), name:'services'
    Template.services.onCreated ->
        @autorun => Meteor.subscribe 'model_counter',('service'), ->
            
    Template.service_edit.onCreated ->
        @autorun => @subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.service_view.onCreated ->
        @autorun => @subscribe 'doc_by_id', Router.current().params.doc_id, ->
        @autorun => @subscribe 'child_docs', Router.current().params.doc_id, ->
            
            
    Template.services.helpers
        total_service_count: -> Counts.get('model_counter') 
        service_docs: ->
            Docs.find 
                model:'service'
    Template.services.events 
        'click .new_service': ->
            new_id = 
                Docs.insert 
                    model:'service'
                    complete:false
            Router.go "/service/#{new_id}/edit"
