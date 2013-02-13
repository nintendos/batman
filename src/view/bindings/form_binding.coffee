#= require ./abstract_attribute_binding

class Batman.DOM.FormBinding extends Batman.DOM.AbstractAttributeBinding
  @current: null
  errorClass: 'error'
  defaultErrorsListSelector: 'div.errors'
  onlyObserve: Batman.BindingDefinitionOnlyObserve.None

  childFileBindings: []

  @accessor 'errorsListSelector', ->
    @get('node').getAttribute('data-errors-list') || @defaultErrorsListSelector

  constructor: ->
    super
    @contextName = @attributeName
    delete @attributeName

    Batman.DOM.events.submit @get('node'), (node, e) -> Batman.DOM.preventDefault e
    @setupErrorsList()

  childBindingAdded: (binding) =>
    if binding.isInputBinding && Batman.isChildOf(@get('node'), binding.get('node'))
      if ~(index = binding.get('key').indexOf(@contextName)) # If the binding is to a key on the thing passed to formfor
        if binding instanceof Batman.DOM.FileBinding# && !!window.FileReader
          @childFileBindings.push(binding)
          @setupUploadPolyfill(binding)

        node = binding.get('node')
        field = binding.get('key').slice(index + @contextName.length + 1) # Slice off up until the context and the following dot
        definition = new Batman.DOM.AttrReaderBindingDefinition(node, @errorClass, @get('keyPath') + " | get 'errors.#{field}.length'", @renderContext, @renderer)
        new Batman.DOM.AddClassBinding(definition)

  setupUploadPolyfill: ->
    model = @renderContext.get(@contextName)

    return if model._batman.saveWithForm
    console.log 'setupUploadPolyfill'
    model._batman.saveWithForm = this

    # We need to unset "saveWithForm" when the FileBinding is destroyed
    # @todo

  setupErrorsList: ->
    if @errorsListNode = Batman.DOM.querySelector(@get('node'), @get('errorsListSelector'))
      Batman.DOM.setInnerHTML @errorsListNode, @errorsListHTML()

      unless @errorsListNode.getAttribute 'data-showif'
        @errorsListNode.setAttribute 'data-showif', "#{@contextName}.errors.length"

  errorsListHTML: ->
    """
    <ul>
      <li data-foreach-error="#{@contextName}.errors" data-bind="error.fullMessage"></li>
    </ul>
    """
