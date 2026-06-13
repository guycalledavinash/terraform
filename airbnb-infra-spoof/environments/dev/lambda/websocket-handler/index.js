exports.handler = async (event) => {
  const routeKey = event.requestContext?.routeKey || '$default';
  console.log(JSON.stringify({ routeKey, connectionId: event.requestContext?.connectionId }));
  return { statusCode: 200, body: JSON.stringify({ ok: true, routeKey }) };
};
