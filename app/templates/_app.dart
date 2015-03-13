library <%= baseName %>;

import 'dart:async';
import 'dart:io';

import 'package:jsonx/jsonx.dart';

import 'package:dart_orm/dart_orm.dart' as ORM;
import 'package:dart_orm_adapter_postgresql/dart_orm_adapter_postgresql.dart';

import 'package:start/start.dart';

<% _.each(entities, function (entity) { %>
part 'models/<%= entity.name %>.dart';
<% }); %>

dynamic initializeOrm() async {
  // This will scan current isolate
  // for classes annotated with DBTable
  // and store sql definitions for them in memory
  await ORM.AnnotationsParser.initialize();

  PostgresqlDBAdapter adapter = new PostgresqlDBAdapter(
    'postgres://postgres:postgres@localhost:5432/mydb');
  await adapter.connect();
  ORM.Model.ormAdapter = adapter;

  List<Future> futures = new List<Future>();
  for (Table t in ORM.AnnotationsParser.ormClasses.values) {
    futures.add(adapter.createTable(t));
  }
  Future.wait(futures).catchError((err) {});
}

void main() {
  initializeOrm();
  start(port: 3000).then((Server app) {
    print("Starting http server on port 3000...");

    app.static('public');

    <% _.each(entities, function (entity) { %>
    app.get('/<%= baseName %>/<%= pluralize(entity.name) %>').listen((request) {
      ORM.Find find = new ORM.Find(<%= _.capitalize(entity.name) %>);

      find.execute().then((List entities) {
        request.response.send(encode(entities));
      });
    });

    app.get('/<%= baseName %>/<%= pluralize(entity.name) %>/:id').listen((request) {
      ORM.FindOne findOne = new ORM.FindOne(<%= _.capitalize(entity.name) %>)
        ..whereEquals('id', request.param('id'));

      findOne.execute().then((<%= _.capitalize(entity.name) %> entity) {
        request.response.send(encode(entity));
      },
      onError: (err) {
        request.status(404).close();
      });
    });

    app.post('/<%= baseName %>/<%= pluralize(entity.name) %>').listen((request) {
      request.input.listen((List<int> buffer) {
        var jsonString = new String.fromCharCodes(buffer);
        <%= _.capitalize(entity.name) %> entity = decode(jsonString, type: <%= _.capitalize(entity.name) %>);
        boolean saveResult = entity.save();
        request.response
          .header('Content-Type', 'application/json; charset=UTF-8')
          .status(201)
          .send(encode(entity));
      });
    });

    app.put('/<%= baseName %>/<%= pluralize(entity.name) %>/:id').listen((request) {
      ORM.FindOne findOne = new ORM.FindOne(<%= _.capitalize(entity.name) %>)
        ..whereEquals('id', request.param('id'));

      findOne.execute().then((<%= _.capitalize(entity.name) %> entity) {
        request.input.listen((List<int> buffer) {
          var jsonString = new String.fromCharCodes(buffer);
          <%= _.capitalize(entity.name) %> entity = decode(jsonString, type: <%= _.capitalize(entity.name) %>);
          boolean saveResult = entity.save();
          request.response
            .header('Content-Type', 'application/json; charset=UTF-8')
            .send(encode(entity));
        });
      },
      onError: (err) {
        request.status(404).close();
      });
    });

    app.delete('/<%= baseName %>/<%= pluralize(entity.name) %>/:id').listen((request) {
      ORM.FindOne findOne = new ORM.FindOne(<%= _.capitalize(entity.name) %>)
        ..whereEquals('id', request.param('id'));

      findOne.execute().then((<%= _.capitalize(entity.name) %> entity) {
        boolean deleteResult = entity.delete();
        request.response
          .header('Content-Type', 'application/json; charset=UTF-8')
          .status(204)
          .send(encode(entity));
      },
      onError: (err) {
        request.status(404).close();
      });
    });
    <% }); %>

  });
}
