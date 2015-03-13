part of <%= baseName %>;

@ORM.DBTable('<%= pluralize(name) %>')
class <%= _.capitalize(name) %> extends ORM.Model {
  @ORM.DBField()
  @ORM.DBFieldPrimaryKey()
  @ORM.DBFieldType('SERIAL')
  int id;

  <% _.each(attrs, function (attr) { %>
  @ORM.DBField()
  <%= attr.attrImplType %> <%= attr.attrName %>;
  <% }); %>
}
